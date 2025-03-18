package eks

import (
	"encoding/json"
	"fmt"
	"maps"
	"strconv"

	"bi/pkg/cluster/util"

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

// NOTE(jdt): This is static for the next ~10 years. We could programmatically
// grab this but it probably isn't worth it at this point
const AWS_OIDC_THUMBPRINT = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"

type clusterConfig struct {
	// config
	baseName     string
	version      string
	defaultTags  map[string]string
	amiType      string
	capacityType string
	// TODO(jdt): allow selecting multiple types
	instanceType string
	desiredSize  int
	maxSize      int
	minSize      int
	volumeSize   int
	volumeType   string

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
	managedNodeGroup *peks.NodeGroup
}

func (c *clusterConfig) withConfig(cfg *util.PulumiConfig) error {
	c.baseName = cfg.Cluster.Name
	c.version = cfg.Cluster.Version
	c.defaultTags = cfg.AWS.DefaultTags
	c.amiType = cfg.Cluster.AmiType
	c.capacityType = cfg.Cluster.CapacityType
	c.instanceType = cfg.Cluster.InstanceType
	c.desiredSize = cfg.Cluster.DesiredSize
	c.maxSize = cfg.Cluster.MaxSize
	c.minSize = cfg.Cluster.MinSize
	c.volumeSize = cfg.Cluster.VolumeSize
	c.volumeType = cfg.Cluster.VolumeType

	return nil
}

func (c *clusterConfig) withOutputs(outputs map[string]auto.OutputMap) error {
	if outputs["vpc"]["vpcID"].Value != nil {
		c.vpcID = outputs["vpc"]["vpcID"].Value.(string)
	}

	if outputs["gateway"]["securityGroupID"].Value != nil {
		c.gatewaySecurityGroupID = outputs["gateway"]["securityGroupID"].Value.(string)
	}

	if outputs["vpc"]["publicSubnetIDs"].Value != nil {
		c.publicSubnetIDs = util.ToStringSlice(outputs["vpc"]["publicSubnetIDs"].Value)
	}

	if outputs["vpc"]["privateSubnetIDs"].Value != nil {
		c.privateSubnetIDs = util.ToStringSlice(outputs["vpc"]["privateSubnetIDs"].Value)
	}

	return nil
}

func (c *clusterConfig) run(ctx *pulumi.Context) error {
	c.securityGroupIDs = make(map[string]pulumi.IDOutput)
	c.roles = make(map[string]*iam.Role)
	c.managedPolicies = []string{}
	c.inlinePolicies = []pulumi.Resource{}

	for _, fn := range []func(*pulumi.Context) error{
		c.buildSecurityGroups,
		c.buildClusterSecurityGroupRules,
		c.buildNodeSecurityGroupRules,
		c.buildCloudwatchLogGroup,
		c.buildKMSKey,
		c.getManagedPolicies,
		c.buildClusterRole,
		c.buildRoleInlinePolicies,
		c.buildRoleManagedPolicies,
		c.buildEKSCluster,
		c.buildKMSKeyPolicy,
		c.buildManagedNodeRole,
		c.buildLaunchTemplate,
		c.buildManagedNodeGroup,
		c.buildOIDCProvider,
		c.buildEBSCSIRole,
		c.buildAddons,
	} {
		if err := fn(ctx); err != nil {
			return err
		}
	}

	ctx.Export("arn", c.cluster.Arn)
	ctx.Export("certificateAuthority", c.cluster.CertificateAuthority.Data())
	ctx.Export("endpoint", c.cluster.Endpoint)
	ctx.Export("name", c.cluster.Name)
	ctx.Export("nodeRoleARN", c.roles["node"].Arn) // we'll use this role for the karpenter nodes as well
	ctx.Export("nodeRoleName", c.roles["node"].Name)
	ctx.Export("oidcProviderURL", c.provider.Url)
	ctx.Export("oidcProviderARN", c.provider.Arn)

	return nil
}

func (c *clusterConfig) buildSecurityGroups(ctx *pulumi.Context) error {
	for _, s := range []string{"cluster", "node"} {
		name := fmt.Sprintf("%s-%s-security-group", c.baseName, s)
		tags := pulumi.StringMap{"Name": pulumi.String(name)}

		if s == "node" {
			tags["karpenter.sh/discovery"] = pulumi.String(c.baseName)
		}

		sg, err := ec2.NewSecurityGroup(ctx, name, &ec2.SecurityGroupArgs{
			Name:        pulumi.String(name),
			Description: pulumi.String("EKS security group - " + s),
			VpcId:       pulumi.String(c.vpcID),
			Tags:        tags,
		})
		if err != nil {
			return fmt.Errorf("error registering security group %s: %w", name, err)
		}
		c.securityGroupIDs[s] = sg.ID()
	}

	return nil
}

func (c *clusterConfig) buildClusterSecurityGroupRules(ctx *pulumi.Context) error {
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
			return fmt.Errorf("error registering security group rule %s: %w", name, err)
		}
	}

	return nil
}

func (c *clusterConfig) buildNodeSecurityGroupRules(ctx *pulumi.Context) error {
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
			return fmt.Errorf("error registering security group ingress rule %s: %w", name, err)
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
		return fmt.Errorf("error registering security group egress rule %s: %w", name, err)
	}

	return nil
}

func (c *clusterConfig) buildKMSKey(ctx *pulumi.Context) error {
	key, err := kms.NewKey(ctx, c.baseName, &kms.KeyArgs{
		DeletionWindowInDays: pulumi.Int(30),
		Description:          pulumi.Sprintf("Cluster encryption key for %s", c.baseName),
		EnableKeyRotation:    P_BOOL_PTR_TRUE,
	})
	if err != nil {
		return fmt.Errorf("error registering KMS key %s: %w", c.baseName, err)
	}
	c.key = key

	_, err = kms.NewAlias(ctx, c.baseName, &kms.AliasArgs{
		Name:        pulumi.Sprintf("alias/eks/%s", c.baseName),
		TargetKeyId: key.KeyId,
	})
	if err != nil {
		return fmt.Errorf("error registering KMS alias %s: %w", c.baseName, err)
	}

	return nil
}

func (c *clusterConfig) buildCloudwatchLogGroup(ctx *pulumi.Context) error {
	// NOTE(jdt): format is `/aws/eks/{cluster_name}/cluster`
	// https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html#viewing-control-plane-logs
	name := fmt.Sprintf("/aws/eks/%s/cluster", c.baseName)
	group, err := cloudwatch.NewLogGroup(ctx, name, &cloudwatch.LogGroupArgs{
		Name:            pulumi.String(name),
		RetentionInDays: pulumi.Int(90),
		Tags:            pulumi.StringMap{"Name": pulumi.String(name)},
	})
	if err != nil {
		return fmt.Errorf("error registering cloudwatch log group %s: %w", name, err)
	}

	c.logGroup = group

	return nil
}

func (c *clusterConfig) getManagedPolicies(ctx *pulumi.Context) error {
	for _, policyName := range []string{
		"AmazonEKSClusterPolicy",
		"AmazonEKSVPCResourceController",
	} {
		policy, err := iam.LookupPolicy(ctx, &iam.LookupPolicyArgs{
			Name: pulumi.StringRef(policyName),
		})
		if err != nil {
			return fmt.Errorf("error looking up IAM policy %s: %w", policyName, err)
		}
		c.managedPolicies = append(c.managedPolicies, policy.Arn)
	}

	return nil
}

func (c *clusterConfig) buildClusterRole(ctx *pulumi.Context) error {
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
		return fmt.Errorf("error registering IAM role %s: %w", c.baseName, err)
	}
	c.roles["cluster"] = role

	return nil
}

func (c *clusterConfig) buildRoleInlinePolicies(ctx *pulumi.Context) error {

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
			return fmt.Errorf("error registering IAM role policy %s: %w", name, err)
		}
		c.inlinePolicies = append(c.inlinePolicies, rp)

	}

	return nil
}

func (c *clusterConfig) buildRoleManagedPolicies(ctx *pulumi.Context) error {
	for _, managedPolicy := range c.managedPolicies {
		name := fmt.Sprintf("%s-%s", c.baseName, managedPolicy)
		_, err := iam.NewRolePolicyAttachment(ctx, name, &iam.RolePolicyAttachmentArgs{
			PolicyArn: pulumi.String(managedPolicy),
			Role:      c.roles["cluster"].Name,
		})
		if err != nil {
			return fmt.Errorf("error registering IAM role policy attachment %s: %w", name, err)
		}
	}

	return nil
}

func (c *clusterConfig) buildEKSCluster(ctx *pulumi.Context) error {
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
		Version: pulumi.String(c.version),
	}, depends)
	if err != nil {
		return fmt.Errorf("error registering EKS cluster %s: %w", c.baseName, err)
	}

	c.cluster = cluster

	return nil
}

func (c *clusterConfig) buildKMSKeyPolicy(ctx *pulumi.Context) error {
	id, err := aws.GetCallerIdentity(ctx, nil)
	if err != nil {
		return fmt.Errorf("error getting caller identity: %w", err)
	}

	session, err := iam.GetSessionContext(ctx, &iam.GetSessionContextArgs{Arn: id.Arn})
	if err != nil {
		return fmt.Errorf("error getting IAM session context: %w", err)
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
	if err != nil {
		return fmt.Errorf("error registering KMS key policy %s: %w", c.baseName, err)
	}

	return nil
}

func (c *clusterConfig) buildManagedNodeRole(ctx *pulumi.Context) error {
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

	// this role is also used for e.g. karpenter nodes
	name := fmt.Sprintf("%s-managed-node-role", c.baseName)
	role, err := iam.NewRole(ctx, name, &iam.RoleArgs{
		AssumeRolePolicy: assumeRole.Json(),
	})
	if err != nil {
		return fmt.Errorf("error registering IAM role %s: %w", name, err)
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
			return fmt.Errorf("error looking up IAM policy %s: %w", policyName, err)
		}

		attach := fmt.Sprintf("%s-%s", name, policyName)
		_, err = iam.NewRolePolicyAttachment(ctx, attach, &iam.RolePolicyAttachmentArgs{
			PolicyArn: pulumi.String(policy.Arn),
			Role:      role.Name,
		})
		if err != nil {
			return fmt.Errorf("error registering IAM role policy attachment %s: %w", policyName, err)
		}
	}

	return nil
}

func (c *clusterConfig) buildLaunchTemplate(ctx *pulumi.Context) error {
	name := fmt.Sprintf("%s-bootstrap", c.baseName)

	// merge the tags that we want applied with the default tags
	tags := map[string]string{"Name": name}
	maps.Copy(tags, c.defaultTags)

	template, err := ec2.NewLaunchTemplate(ctx, name, &ec2.LaunchTemplateArgs{
		EbsOptimized: P_STR_TRUE,
		BlockDeviceMappings: &ec2.LaunchTemplateBlockDeviceMappingArray{
			&ec2.LaunchTemplateBlockDeviceMappingArgs{
				DeviceName: pulumi.StringPtr("/dev/xvda"),
				Ebs: &ec2.LaunchTemplateBlockDeviceMappingEbsArgs{
					Encrypted:           P_STR_TRUE,
					DeleteOnTermination: P_STR_TRUE,
					VolumeSize:          pulumi.Int(c.volumeSize),
					VolumeType:          pulumi.String(c.volumeType),
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
		return fmt.Errorf("error registering EC2 launch template %s: %w", name, err)
	}

	c.template = template

	return nil
}

func (c *clusterConfig) buildManagedNodeGroup(ctx *pulumi.Context) error {
	vsn := c.template.DefaultVersion.ApplyT(func(i int) string {
		return strconv.Itoa(i)
	}).(pulumi.StringOutput)

	name := fmt.Sprintf("%s-bootstrap", c.baseName)
	ng, err := peks.NewNodeGroup(ctx, name, &peks.NodeGroupArgs{
		AmiType:       pulumi.String(c.amiType),
		CapacityType:  pulumi.String(c.capacityType),
		ClusterName:   c.cluster.Name,
		InstanceTypes: pulumi.ToStringArray([]string{c.instanceType}),
		NodeRoleArn:   c.roles["node"].Arn,
		SubnetIds:     pulumi.ToStringArray(c.privateSubnetIDs),
		Version:       pulumi.String(c.version),
		LaunchTemplate: &peks.NodeGroupLaunchTemplateArgs{
			Id:      c.template.ID(),
			Version: vsn,
		},
		ScalingConfig: &peks.NodeGroupScalingConfigArgs{
			DesiredSize: pulumi.Int(c.desiredSize),
			MaxSize:     pulumi.Int(c.maxSize),
			MinSize:     pulumi.Int(c.minSize),
		},
		Taints: &peks.NodeGroupTaintArray{
			&peks.NodeGroupTaintArgs{
				Effect: pulumi.String("NO_SCHEDULE"),
				Key:    pulumi.String("CriticalAddonsOnly"),
				Value:  P_STR_TRUE,
			},
		},
		UpdateConfig: &peks.NodeGroupUpdateConfigArgs{
			MaxUnavailable: pulumi.Int(1),
		},
	}, pulumi.DependsOn([]pulumi.Resource{c.template}))
	if err != nil {
		return fmt.Errorf("error registering EKS node group %s: %w", name, err)
	}

	c.managedNodeGroup = ng

	return nil
}

func (c *clusterConfig) buildOIDCProvider(ctx *pulumi.Context) error {
	url := c.cluster.Identities.ApplyT(func(ids []peks.ClusterIdentity) string {
		return *ids[0].Oidcs[0].Issuer
	}).(pulumi.StringOutput)

	p, err := iam.NewOpenIdConnectProvider(ctx, c.baseName, &iam.OpenIdConnectProviderArgs{
		ClientIdLists:   P_STR_ARR_STS_AMAZONAWS_COM,
		ThumbprintLists: pulumi.ToStringArray([]string{AWS_OIDC_THUMBPRINT}),
		Url:             url,
	}, pulumi.DependsOn([]pulumi.Resource{c.cluster}))
	if err != nil {
		return fmt.Errorf("error registering OIDC provider %s: %w", c.baseName, err)
	}

	c.provider = p

	return nil
}

func (c *clusterConfig) buildEBSCSIRole(ctx *pulumi.Context) error {
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

	ebsCSIPolicy, err := iam.LookupPolicy(ctx, &iam.LookupPolicyArgs{
		Name: pulumi.StringRef("AmazonEBSCSIDriverPolicy"),
	})
	if err != nil {
		return fmt.Errorf("error looking up EBS CSI IAM policy: %w", err)
	}

	name := fmt.Sprintf("%s-ebs-csi", c.baseName)
	role, err := iam.NewRole(ctx, name, &iam.RoleArgs{
		AssumeRolePolicy:  assumeRole.Json(),
		ManagedPolicyArns: pulumi.ToStringArray([]string{ebsCSIPolicy.Arn}),
	})
	if err != nil {
		return fmt.Errorf("error registering IAM role %s: %w", name, err)
	}

	c.roles["ebs-csi"] = role

	return nil
}

func (c *clusterConfig) buildAddons(ctx *pulumi.Context) error {
	bs, err := json.Marshal(map[string]interface{}{
		"resources": map[string]interface{}{
			"limits":   map[string]string{"cpu": "0.25", "memory": "256M"},
			"requests": map[string]string{"cpu": "0.25", "memory": "256M"},
		},
	})
	if err != nil {
		return fmt.Errorf("error marshalling coredns resources config: %w", err)
	}

	for addon, config := range map[string]struct {
		irsaARN pulumi.StringPtrInput
		config  pulumi.StringPtrInput
	}{
		"aws-ebs-csi-driver":  {irsaARN: c.roles["ebs-csi"].Arn},
		"coredns":             {config: pulumi.String(bs)},
		"kube-proxy":          {},
		"snapshot-controller": {},
		"vpc-cni":             {},
	} {
		version, err := peks.GetAddonVersion(ctx, &peks.GetAddonVersionArgs{
			AddonName:         addon,
			KubernetesVersion: c.version,
			MostRecent:        pulumi.BoolRef(true),
		})
		if err != nil {
			return fmt.Errorf("error getting EKS addon version %s: %w", addon, err)
		}

		name := fmt.Sprintf("%s-addon-%s", c.baseName, addon)
		_, err = peks.NewAddon(ctx, name, &peks.AddonArgs{
			AddonName:             pulumi.String(addon),
			AddonVersion:          pulumi.String(version.Version),
			ClusterName:           c.cluster.Name,
			ConfigurationValues:   config.config,
			ServiceAccountRoleArn: config.irsaARN,
		}, pulumi.DependsOn([]pulumi.Resource{c.managedNodeGroup}))
		if err != nil {
			return fmt.Errorf("error registering EKS addon %s: %w", name, err)
		}
	}

	return nil
}
