package eks

import (
	"encoding/json"
	"fmt"
	"maps"
	"strconv"

	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws"
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/cloudwatch"
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/ec2"
	peks "github.com/pulumi/pulumi-aws/sdk/v6/go/aws/eks"
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/iam"
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/kms"
	pvpc "github.com/pulumi/pulumi-aws/sdk/v6/go/aws/vpc"

	"github.com/pulumi/pulumi/sdk/v3/go/auto"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

type cluster struct {
	// config
	baseName    string
	version     string
	defaultTags map[string]string

	// outputs
	vpcID                  string
	gatewaySecurityGroupID string
	publicSubnetIDs        []string
	privateSubnetIDs       []string

	// state
	securityGroupIDs map[string]pulumi.IDOutput
	logGroup         *cloudwatch.LogGroup
	key              *kms.Key
	managedPolicies  []string
	roles            map[string]*iam.Role
	inlinePolicies   []pulumi.Resource
	cluster          *peks.Cluster
	provider         *iam.OpenIdConnectProvider
	template         *ec2.LaunchTemplate
}

// TODO(jdt): reflexively get config values based on struct tags
func (c *cluster) withConfig(cfg auto.ConfigMap) error {
	tags, err := parseDefaultTags(cfg["aws:defaultTags"].Value)
	if err != nil {
		return err
	}

	c.baseName = cfg["cluster:name"].Value
	c.version = cfg["cluster:version"].Value
	c.defaultTags = tags

	return nil
}

func parseDefaultTags(s string) (map[string]string, error) {
	// don't use Tags as we want to keep the full tags and it doesn't make
	// sense to go unmarshal and then re-marshal?
	raw := map[string]interface{}{}
	if err := json.Unmarshal([]byte(s), &raw); err != nil {
		return nil, err
	}

	inner, ok := raw["tags"].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("tags not in correct format")
	}

	tags := make(map[string]string)
	for k, v := range inner {
		tags[k] = v.(string)
	}

	return tags, nil

}

func (c *cluster) withOutputs(outputs map[string]auto.OutputMap) error {
	c.vpcID = outputs["vpc"]["vpcID"].Value.(string)
	c.gatewaySecurityGroupID = outputs["gateway"]["gatewaySecurityGroupID"].Value.(string)
	c.publicSubnetIDs = toStringSlice(outputs["vpc"]["publicSubnetIDs"].Value)
	c.privateSubnetIDs = toStringSlice(outputs["vpc"]["privateSubnetIDs"].Value)

	return nil
}

func (c *cluster) run(ctx *pulumi.Context) error {
	c.securityGroupIDs = make(map[string]pulumi.IDOutput)
	c.roles = make(map[string]*iam.Role)
	c.managedPolicies = []string{}
	c.inlinePolicies = []pulumi.Resource{}

	for _, fn := range []func(*pulumi.Context) error{
		c.securityGroups,
		c.clusterSecurityGroupRules,
		c.nodeSecurityGroupRules,
		c.cloudwatchLogGroup,
		c.kmsKey,
		c.getManagedPolicies,
		c.clusterRole,
		c.roleInlinePolicies,
		c.roleManagedPolicies,
		c.eksCluster,
		c.kmsKeyPolicy,
		c.managedNodeRole,
		c.launchTemplate,
		c.managedNodeGroup,
		c.oidcProvider,
		c.ebsCSIRole,
		c.addons,
	} {
		if err := fn(ctx); err != nil {
			return err
		}
	}

	ctx.Export("oidcProviderURL", c.provider.Url)
	ctx.Export("oidcProviderARN", c.provider.Arn)

	return nil
}

func (c *cluster) securityGroups(ctx *pulumi.Context) error {
	for _, s := range []string{"cluster", "node"} {
		name := fmt.Sprintf("%s-%s-security-group", c.baseName, s)
		sg, err := ec2.NewSecurityGroup(ctx, name, &ec2.SecurityGroupArgs{
			Name:        pulumi.String(name),
			Description: pulumi.String("EKS security group - " + s),
			VpcId:       pulumi.String(c.vpcID),
			Tags:        pulumi.StringMap{"Name": pulumi.String(name)},
		})
		if err != nil {
			return err
		}
		c.securityGroupIDs[s] = sg.ID()

	}

	return nil
}

func (c *cluster) clusterSecurityGroupRules(ctx *pulumi.Context) error {
	port := pulumi.Int(443)

	for rule, rsgID := range map[string]pulumi.StringPtrInput{
		"node-to-cluster-api":    c.securityGroupIDs["node"],
		"gateway-to-cluster-api": pulumi.StringPtr(c.gatewaySecurityGroupID),
	} {
		name := fmt.Sprintf("%s-%s", c.baseName, rule)
		_, err := pvpc.NewSecurityGroupIngressRule(ctx, name, &pvpc.SecurityGroupIngressRuleArgs{
			SecurityGroupId:           c.securityGroupIDs["cluster"],
			FromPort:                  port,
			ToPort:                    port,
			IpProtocol:                P_STR_TCP,
			ReferencedSecurityGroupId: rsgID,
			Tags:                      pulumi.StringMap{"Name": pulumi.String(name)},
		})
		if err != nil {
			return err
		}
	}

	return nil
}

func (c *cluster) nodeSecurityGroupRules(ctx *pulumi.Context) error {
	sgID := c.securityGroupIDs["node"]

	// NOTE(jdt): we need to audit this. In the terraform, there are specific ports and protocols specifically allowed but then an "allow all" rule.
	// To simplify the migration, I'm just migrating the allow all rules.
	for sg, rsgID := range c.securityGroupIDs {
		name := fmt.Sprintf("%s-%s-allow-all", c.baseName, sg)
		desc := pulumi.Sprintf("Allow traffic from %s security group", sg)

		_, err := pvpc.NewSecurityGroupIngressRule(ctx, name, &pvpc.SecurityGroupIngressRuleArgs{
			SecurityGroupId:           sgID,
			IpProtocol:                pulumi.String("-1"),
			ReferencedSecurityGroupId: rsgID,
			Description:               desc,
			Tags:                      pulumi.StringMap{"Name": pulumi.String(name)},
		})
		if err != nil {
			return err
		}
	}

	name := fmt.Sprintf("%s-egress-all", c.baseName)
	_, err := pvpc.NewSecurityGroupEgressRule(ctx, name, &pvpc.SecurityGroupEgressRuleArgs{
		SecurityGroupId: sgID,
		IpProtocol:      pulumi.String("-1"),
		CidrIpv4:        pulumi.String("0.0.0.0/0"),
		Tags:            pulumi.StringMap{"Name": pulumi.String(name)},
	})
	if err != nil {
		return err
	}

	return nil
}

func (c *cluster) kmsKey(ctx *pulumi.Context) error {
	key, err := kms.NewKey(ctx, c.baseName, &kms.KeyArgs{
		DeletionWindowInDays: pulumi.Int(30),
		Description:          pulumi.Sprintf("Cluster encryption key for %s", c.baseName),
		EnableKeyRotation:    P_BOOL_PTR_TRUE,
	})
	if err != nil {
		return err
	}
	c.key = key

	_, err = kms.NewAlias(ctx, c.baseName, &kms.AliasArgs{
		Name:        pulumi.Sprintf("alias/eks/%s", c.baseName),
		TargetKeyId: key.KeyId,
	})
	if err != nil {
		return err
	}

	return nil
}

func (c *cluster) cloudwatchLogGroup(ctx *pulumi.Context) error {
	// https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html#viewing-control-plane-logs
	// format is `/aws/eks/{cluster_name}/cluster`
	name := fmt.Sprintf("/aws/eks/%s/cluster", c.baseName)
	group, err := cloudwatch.NewLogGroup(ctx, name, &cloudwatch.LogGroupArgs{
		Name:            pulumi.String(name),
		RetentionInDays: pulumi.Int(90),
		Tags:            pulumi.StringMap{"Name": pulumi.String(name)},
	})
	if err != nil {
		return err
	}

	c.logGroup = group
	return nil
}

func (c *cluster) getManagedPolicies(ctx *pulumi.Context) error {
	for _, policyName := range []string{
		"AmazonEKSClusterPolicy",
		"AmazonEKSVPCResourceController",
	} {
		policy, err := iam.LookupPolicy(ctx, &iam.LookupPolicyArgs{
			Name: pulumi.StringRef(policyName),
		})
		if err != nil {
			return err
		}
		c.managedPolicies = append(c.managedPolicies, policy.Arn)
	}

	return nil
}

func (c *cluster) clusterRole(ctx *pulumi.Context) error {
	assumeRole := iam.GetPolicyDocumentOutput(ctx, iam.GetPolicyDocumentOutputArgs{
		Statements: iam.GetPolicyDocumentStatementArray{
			iam.GetPolicyDocumentStatementArgs{
				Effect: P_STR_ALLOW,
				Principals: iam.GetPolicyDocumentStatementPrincipalArray{
					iam.GetPolicyDocumentStatementPrincipalArgs{
						Type:        P_STR_SERVICE,
						Identifiers: P_STR_ARR_EKS_AMAZONAWS_COM,
					},
				},
				Actions: P_STR_ARR_STS_ASSUME_ROLE,
			},
		},
	})

	role, err := iam.NewRole(ctx, c.baseName, &iam.RoleArgs{
		AssumeRolePolicy: assumeRole.Json(),
	})
	if err != nil {
		return err
	}
	c.roles["cluster"] = role

	return nil
}

// roleInlinePolicies creates the inline role policies
// Because we want to use the Arn output of the kms key, we have to wrap the resources in outputs and use apply
func (c *cluster) roleInlinePolicies(ctx *pulumi.Context) error {

	for svc, policy := range map[string]struct {
		actions  []string
		resource pulumi.StringOutput
		effect   pulumi.String
	}{
		"logs": {
			effect: P_STR_DENY,
			actions: []string{
				"logs:CreateLogGroup",
			},
			resource: pulumi.String("*").ToStringOutput(),
		},
		"kms": {
			effect: P_STR_ALLOW,
			actions: []string{
				"kms:Encrypt",
				"kms:Decrypt",
				"kms:ListGrants",
				"kms:DescribeKey",
			},
			resource: c.key.Arn,
		},
	} {
		stmt := iam.GetPolicyDocumentOutput(ctx, iam.GetPolicyDocumentOutputArgs{
			Statements: iam.GetPolicyDocumentStatementArray{
				iam.GetPolicyDocumentStatementArgs{
					Actions:   pulumi.ToStringArray(policy.actions),
					Effect:    policy.effect,
					Resources: pulumi.ToStringArrayOutput([]pulumi.StringOutput{policy.resource}),
				},
			},
		})

		name := fmt.Sprintf("%s-%s-policy", c.baseName, svc)
		rp, err := iam.NewRolePolicy(ctx, name, &iam.RolePolicyArgs{
			Policy: stmt.Json(),
			Role:   c.roles["cluster"].ID(),
		})
		if err != nil {
			return err
		}
		c.inlinePolicies = append(c.inlinePolicies, rp)

	}

	return nil
}

func (c *cluster) roleManagedPolicies(ctx *pulumi.Context) error {
	for _, managedPolicy := range c.managedPolicies {
		name := fmt.Sprintf("%s-%s", c.baseName, managedPolicy)
		_, err := iam.NewRolePolicyAttachment(ctx, name, &iam.RolePolicyAttachmentArgs{
			PolicyArn: pulumi.String(managedPolicy),
			Role:      c.roles["cluster"].Name,
		})
		if err != nil {
			return err
		}
	}

	return nil
}

func (c *cluster) eksCluster(ctx *pulumi.Context) error {
	depends := pulumi.DependsOn(append(c.inlinePolicies, []pulumi.Resource{c.logGroup, c.key}...))

	cluster, err := peks.NewCluster(ctx, c.baseName, &peks.ClusterArgs{
		EnabledClusterLogTypes: pulumi.ToStringArray([]string{"api", "audit", "authenticator"}),
		EncryptionConfig: &peks.ClusterEncryptionConfigArgs{
			Provider: &peks.ClusterEncryptionConfigProviderArgs{
				KeyArn: c.key.Arn,
			},
			Resources: pulumi.ToStringArray([]string{"secrets"}),
		},
		Name:    pulumi.String(c.baseName),
		RoleArn: c.roles["cluster"].Arn,
		VpcConfig: &peks.ClusterVpcConfigArgs{
			EndpointPrivateAccess: P_BOOL_PTR_TRUE,
			EndpointPublicAccess:  P_BOOL_PTR_FALSE,
			SecurityGroupIds:      pulumi.StringArray{c.securityGroupIDs["cluster"]},
			SubnetIds:             pulumi.ToStringArray(c.privateSubnetIDs),
		},
	}, depends)
	if err != nil {
		return err
	}

	c.cluster = cluster
	return nil
}

func (c *cluster) kmsKeyPolicy(ctx *pulumi.Context) error {
	id, err := aws.GetCallerIdentity(ctx, nil)
	if err != nil {
		return err
	}

	session, err := iam.GetSessionContext(ctx, &iam.GetSessionContextArgs{Arn: id.Arn})
	if err != nil {
		return err
	}

	policy := iam.GetPolicyDocumentOutput(ctx, iam.GetPolicyDocumentOutputArgs{
		Statements: iam.GetPolicyDocumentStatementArray{
			iam.GetPolicyDocumentStatementArgs{
				Effect: P_STR_ALLOW,
				Principals: iam.GetPolicyDocumentStatementPrincipalArray{
					iam.GetPolicyDocumentStatementPrincipalArgs{
						Type:        P_STR_AWS,
						Identifiers: pulumi.ToStringArray([]string{session.IssuerArn}),
					},
				},
				Actions: pulumi.ToStringArray([]string{
					"kms:Update*",
					"kms:UntagResource",
					"kms:TagResource",
					"kms:ScheduleKeyDeletion",
					"kms:Revoke*",
					"kms:ReplicateKey",
					"kms:Put*",
					"kms:List*",
					"kms:ImportKeyMaterial",
					"kms:Get*",
					"kms:Enable*",
					"kms:Disable*",
					"kms:Describe*",
					"kms:Delete*",
					"kms:Create*",
					"kms:CancelKeyDeletion",
				}),
				Resources: P_STR_ARR_WILDCARD,
			},
			iam.GetPolicyDocumentStatementArgs{
				Effect: P_STR_ALLOW,
				Principals: iam.GetPolicyDocumentStatementPrincipalArray{
					iam.GetPolicyDocumentStatementPrincipalArgs{
						Type:        P_STR_AWS,
						Identifiers: pulumi.ToStringArrayOutput([]pulumi.StringOutput{c.roles["cluster"].Arn}),
					},
				},
				Actions: pulumi.ToStringArray([]string{
					"kms:ReEncrypt*",
					"kms:GenerateDataKey*",
					"kms:Encrypt",
					"kms:DescribeKey",
					"kms:Decrypt",
				}),
				Resources: P_STR_ARR_WILDCARD,
			},
		},
	})

	_, err = kms.NewKeyPolicy(ctx, c.baseName, &kms.KeyPolicyArgs{
		KeyId:  c.key.KeyId,
		Policy: policy.Json(),
	})
	return err
}

func (c *cluster) managedNodeRole(ctx *pulumi.Context) error {
	assumeRole := iam.GetPolicyDocumentOutput(ctx, iam.GetPolicyDocumentOutputArgs{
		Statements: iam.GetPolicyDocumentStatementArray{
			iam.GetPolicyDocumentStatementArgs{
				Actions: P_STR_ARR_STS_ASSUME_ROLE,
				Effect:  P_STR_ALLOW,
				Principals: iam.GetPolicyDocumentStatementPrincipalArray{
					iam.GetPolicyDocumentStatementPrincipalArgs{
						Type:        P_STR_SERVICE,
						Identifiers: P_STR_ARR_EC2_AMAZONAWS_COM,
					},
				},
			},
		},
	})

	name := fmt.Sprintf("%s-managed-node-role", c.baseName)
	role, err := iam.NewRole(ctx, name, &iam.RoleArgs{
		AssumeRolePolicy: assumeRole.Json(),
	})
	if err != nil {
		return err
	}

	c.roles["node"] = role

	for _, policyName := range []string{
		"AmazonSSMManagedInstanceCore",
		"AmazonEKS_CNI_Policy",
		"AmazonEC2ContainerRegistryReadOnly",
		"AmazonEKSWorkerNodePolicy",
	} {
		policy, err := iam.LookupPolicy(ctx, &iam.LookupPolicyArgs{
			Name: pulumi.StringRef(policyName),
		})
		if err != nil {
			return err
		}

		attach := fmt.Sprintf("%s-%s", name, policyName)
		_, err = iam.NewRolePolicyAttachment(ctx, attach, &iam.RolePolicyAttachmentArgs{
			PolicyArn: pulumi.String(policy.Arn),
			Role:      role.Name,
		})
		if err != nil {
			return err
		}

	}

	return nil
}

func (c *cluster) launchTemplate(ctx *pulumi.Context) error {
	name := fmt.Sprintf("%s-bootstrap", c.baseName)
	trueStrPtr := pulumi.StringPtr("true")

	// merge the tags that we want applied with the default tags
	tags := map[string]string{"Name": name}
	maps.Copy(tags, c.defaultTags)

	template, err := ec2.NewLaunchTemplate(ctx, name, &ec2.LaunchTemplateArgs{
		EbsOptimized: trueStrPtr,
		BlockDeviceMappings: &ec2.LaunchTemplateBlockDeviceMappingArray{
			&ec2.LaunchTemplateBlockDeviceMappingArgs{
				DeviceName: pulumi.StringPtr("/dev/xvda"),
				Ebs: &ec2.LaunchTemplateBlockDeviceMappingEbsArgs{
					Encrypted:           trueStrPtr,
					DeleteOnTermination: trueStrPtr,
					VolumeSize:          pulumi.IntPtr(20),
					VolumeType:          pulumi.StringPtr("gp3"),
				},
			},
		},
		DisableApiStop:        P_BOOL_PTR_FALSE,
		DisableApiTermination: P_BOOL_PTR_FALSE,
		MetadataOptions: &ec2.LaunchTemplateMetadataOptionsArgs{
			HttpPutResponseHopLimit: pulumi.Int(2),
			HttpTokens:              pulumi.String("required"),
		},
		VpcSecurityGroupIds: pulumi.ToStringArrayOutput(
			[]pulumi.StringOutput{c.securityGroupIDs["node"].ToStringOutput()},
		),
		TagSpecifications: &ec2.LaunchTemplateTagSpecificationArray{
			&ec2.LaunchTemplateTagSpecificationArgs{
				ResourceType: pulumi.StringPtr("instance"),
				Tags:         pulumi.ToStringMap(tags),
			},
		},
		UpdateDefaultVersion: P_BOOL_PTR_TRUE,
	})
	if err != nil {
		return err
	}

	c.template = template
	return nil
}

func (c *cluster) managedNodeGroup(ctx *pulumi.Context) error {
	vsn := c.template.DefaultVersion.ApplyT(func(i int) string {
		return strconv.Itoa(i)
	}).(pulumi.StringOutput)

	name := fmt.Sprintf("%s-bootstrap", c.baseName)
	_, err := peks.NewNodeGroup(ctx, name, &peks.NodeGroupArgs{
		AmiType:       pulumi.StringPtr("AL2_x86_64"),
		CapacityType:  pulumi.StringPtr("ON_DEMAND"),
		ClusterName:   c.cluster.Name,
		InstanceTypes: pulumi.ToStringArray([]string{"t3a.medium"}),
		NodeRoleArn:   c.roles["node"].Arn,
		SubnetIds:     pulumi.ToStringArray(c.privateSubnetIDs),
		Version:       pulumi.StringPtr(c.version),
		LaunchTemplate: &peks.NodeGroupLaunchTemplateArgs{
			Id:      c.template.ID(),
			Version: vsn,
		},
		ScalingConfig: &peks.NodeGroupScalingConfigArgs{
			DesiredSize: pulumi.Int(2),
			MaxSize:     pulumi.Int(4),
			MinSize:     pulumi.Int(2),
		},
		Taints: &peks.NodeGroupTaintArray{
			&peks.NodeGroupTaintArgs{
				Effect: pulumi.String("NO_SCHEDULE"),
				Key:    pulumi.String("CriticalAddonsOnly"),
				Value:  pulumi.String("true"),
			},
		},
		UpdateConfig: &peks.NodeGroupUpdateConfigArgs{
			MaxUnavailable: pulumi.Int(1),
		},
	}, pulumi.DependsOn([]pulumi.Resource{c.cluster, c.template}))
	if err != nil {
		return err
	}
	return nil
}

func (c *cluster) oidcProvider(ctx *pulumi.Context) error {
	url := c.cluster.Identities.ApplyT(func(ids []peks.ClusterIdentity) string {
		return *ids[0].Oidcs[0].Issuer
	}).(pulumi.StringOutput)

	p, err := iam.NewOpenIdConnectProvider(ctx, c.baseName, &iam.OpenIdConnectProviderArgs{
		ClientIdLists:   P_STR_ARR_STS_AMAZONAWS_COM,
		ThumbprintLists: pulumi.ToStringArray([]string{"9e99a48a9960b14926bb7f3b02e22da2b0ab7280"}),
		Url:             url,
	}, pulumi.DependsOn([]pulumi.Resource{c.cluster}))
	if err != nil {
		return err
	}

	c.provider = p

	return nil
}

func (c *cluster) ebsCSIRole(ctx *pulumi.Context) error {
	assumeRole := iam.GetPolicyDocumentOutput(ctx, iam.GetPolicyDocumentOutputArgs{
		Statements: iam.GetPolicyDocumentStatementArray{
			iam.GetPolicyDocumentStatementArgs{
				Actions: P_STR_ARR_STS_ASSUME_ROLE_WEB_IDENTITY,
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_STRING_EQUALS,
						Values:   P_STR_ARR_STS_AMAZONAWS_COM,
						Variable: pulumi.Sprintf("%s:aud", c.provider.Url),
					},
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_STRING_EQUALS,
						Values:   pulumi.ToStringArray([]string{"system:serviceaccount:kube-system:ebs-csi-controller-sa"}),
						Variable: pulumi.Sprintf("%s:sub", c.provider.Url),
					},
				},
				Effect: P_STR_ALLOW,
				Principals: iam.GetPolicyDocumentStatementPrincipalArray{
					iam.GetPolicyDocumentStatementPrincipalArgs{
						Type:        P_STR_FEDERATED,
						Identifiers: pulumi.ToStringArrayOutput([]pulumi.StringOutput{c.provider.Arn}),
					},
				},
			},
		},
	})

	name := fmt.Sprintf("%s-ebs-csi", c.baseName)
	role, err := iam.NewRole(ctx, name, &iam.RoleArgs{
		AssumeRolePolicy: assumeRole.Json(),
	})
	if err != nil {
		return err
	}

	policy := iam.GetPolicyDocumentOutput(ctx, iam.GetPolicyDocumentOutputArgs{
		Statements: iam.GetPolicyDocumentStatementArray{
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"ec2:ModifyVolume",
					"ec2:DetachVolume",
					"ec2:DescribeVolumesModifications",
					"ec2:DescribeVolumes",
					"ec2:DescribeTags",
					"ec2:DescribeSnapshots",
					"ec2:DescribeInstances",
					"ec2:DescribeAvailabilityZones",
					"ec2:CreateSnapshot",
					"ec2:AttachVolume",
				}),
				Effect:    P_STR_ALLOW,
				Resources: P_STR_ARR_WILDCARD,
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{"ec2:CreateTags"}),
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_STRING_EQUALS,
						Values:   pulumi.ToStringArray([]string{"CreateVolume", "CreateSnapshot"}),
						Variable: pulumi.String("ec2:CreateAction"),
					},
				},
				Effect: P_STR_ALLOW,
				Resources: pulumi.ToStringArray([]string{
					"arn:aws:ec2:*:*:volume/*",
					"arn:aws:ec2:*:*:snapshot/*",
				}),
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{"ec2:DeleteTags"}),
				Effect:  P_STR_ALLOW,
				Resources: pulumi.ToStringArray([]string{
					"arn:aws:ec2:*:*:volume/*",
					"arn:aws:ec2:*:*:snapshot/*",
				}),
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{"ec2:CreateVolume"}),
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_STRING_LIKE,
						Values:   P_STR_ARR_TRUE,
						Variable: pulumi.String("aws:RequestTag/ebs.csi.aws.com/cluster"),
					},
				},
				Effect:    P_STR_ALLOW,
				Resources: P_STR_ARR_WILDCARD,
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{"ec2:CreateVolume"}),
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_STRING_LIKE,
						Values:   P_STR_ARR_WILDCARD,
						Variable: pulumi.String("aws:RequestTag/CSIVolumeName"),
					},
				},
				Effect:    P_STR_ALLOW,
				Resources: P_STR_ARR_WILDCARD,
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{"ec2:CreateVolume"}),
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:   P_STR_STRING_LIKE,
						Values: P_STR_ARR_OWNED,
						// NOTE(jdt): we could probably interpolate the cluster name here?
						Variable: pulumi.String("aws:RequestTag/kubernetes.io/cluster/*"),
					},
				},
				Effect:    P_STR_ALLOW,
				Resources: P_STR_ARR_WILDCARD,
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{"ec2:DeleteVolume"}),
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_STRING_LIKE,
						Values:   P_STR_ARR_TRUE,
						Variable: pulumi.String("ec2:ResourceTag/ebs.csi.aws.com/cluster"),
					},
				},
				Effect:    P_STR_ALLOW,
				Resources: P_STR_ARR_WILDCARD,
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{"ec2:DeleteVolume"}),
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_STRING_LIKE,
						Values:   P_STR_ARR_WILDCARD,
						Variable: pulumi.String("ec2:ResourceTag/CSIVolumeName"),
					},
				},
				Effect:    P_STR_ALLOW,
				Resources: P_STR_ARR_WILDCARD,
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{"ec2:DeleteVolume"}),
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:   P_STR_STRING_LIKE,
						Values: P_STR_ARR_OWNED,
						// NOTE(jdt): we could probably interpolate the cluster name here?
						Variable: pulumi.String("ec2:ResourceTag/kubernetes.io/cluster/*"),
					},
				},
				Effect:    P_STR_ALLOW,
				Resources: P_STR_ARR_WILDCARD,
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{"ec2:DeleteVolume"}),
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_STRING_LIKE,
						Values:   P_STR_ARR_WILDCARD,
						Variable: pulumi.String("ec2:ResourceTag/kubernetes.io/created-for/pvc/name"),
					},
				},
				Effect:    P_STR_ALLOW,
				Resources: P_STR_ARR_WILDCARD,
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{"ec2:DeleteSnapshot"}),
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_STRING_LIKE,
						Values:   P_STR_ARR_WILDCARD,
						Variable: pulumi.String("ec2:ResourceTag/CSIVolumeSnapshotName"),
					},
				},
				Effect:    P_STR_ALLOW,
				Resources: P_STR_ARR_WILDCARD,
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{"ec2:DeleteSnapshot"}),
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_STRING_LIKE,
						Values:   P_STR_ARR_TRUE,
						Variable: pulumi.String("ec2:ResourceTag/ebs.csi.aws.com/cluster"),
					},
				},
				Effect:    P_STR_ALLOW,
				Resources: P_STR_ARR_WILDCARD,
			},
		},
	})

	c.roles["ebs-csi"] = role

	_, err = iam.NewRolePolicy(ctx, name, &iam.RolePolicyArgs{
		Role:   role.Name,
		Policy: policy.Json(),
	})
	if err != nil {
		return err
	}

	return nil
}

func (c *cluster) addons(ctx *pulumi.Context) error {
	bs, err := json.Marshal(map[string]interface{}{
		"resources": map[string]interface{}{
			"limits":   map[string]string{"cpu": "0.25", "memory": "256M"},
			"requests": map[string]string{"cpu": "0.25", "memory": "256M"},
		},
	})
	if err != nil {
		return err
	}

	for addon, config := range map[string]struct {
		irsaARN pulumi.StringPtrInput
		config  pulumi.StringPtrInput
	}{
		"aws-ebs-csi-driver": {irsaARN: c.roles["ebs-csi"].Arn},
		"coredns":            {config: pulumi.String(bs)},
		"kube-proxy":         {},
		"vpc-cni":            {},
	} {
		version, err := peks.GetAddonVersion(ctx, &peks.GetAddonVersionArgs{
			AddonName:         addon,
			KubernetesVersion: c.version,
			MostRecent:        pulumi.BoolRef(true),
		})
		if err != nil {
			return err
		}

		name := fmt.Sprintf("%s-addon-%s", c.baseName, addon)
		_, err = peks.NewAddon(ctx, name, &peks.AddonArgs{
			AddonName:             pulumi.String(addon),
			AddonVersion:          pulumi.String(version.Version),
			ClusterName:           c.cluster.Name,
			ConfigurationValues:   config.config,
			ServiceAccountRoleArn: config.irsaARN,
		})
		if err != nil {
			return err
		}
	}
	return nil
}
