package eks

import (
	"fmt"

	"bi/pkg/cluster/util"

	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws"
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/iam"
	"github.com/pulumi/pulumi/sdk/v3/go/auto"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

const (
	KARPENTER_NAME     = "karpenter"
	LB_CONTROLLER_NAME = "aws-load-balancer-controller"
)

type rolesConfig struct {
	// config
	baseName string

	// outputs
	clusterARN,
	oidcProviderURL,
	oidcProviderARN string

	// state
	roles map[string]*iam.Role
}

func (l *rolesConfig) withConfig(cfg *util.PulumiConfig) error {
	l.baseName = cfg.Cluster.Name

	return nil
}

func (l *rolesConfig) withOutputs(outputs map[string]auto.OutputMap) error {
	l.clusterARN = outputs["cluster"]["arn"].Value.(string)
	l.oidcProviderURL = outputs["cluster"]["oidcProviderURL"].Value.(string)
	l.oidcProviderARN = outputs["cluster"]["oidcProviderARN"].Value.(string)
	return nil
}

func (l *rolesConfig) run(ctx *pulumi.Context) error {
	l.roles = make(map[string]*iam.Role)
	for _, fn := range []func(*pulumi.Context) error{
		l.lbControllerRole,
		l.karpenterNodeRole,
		l.karpenterServiceRole,
	} {
		if err := fn(ctx); err != nil {
			return err
		}
	}

	ctx.Export("karpenterServiceRoleARN", l.roles["karpenterService"].Arn)
	ctx.Export("lbControllerRoleARN", l.roles["lbController"].Arn)

	return nil
}

func (l *rolesConfig) lbControllerRole(ctx *pulumi.Context) error {
	assumeRole := iam.GetPolicyDocumentOutput(ctx, iam.GetPolicyDocumentOutputArgs{
		Statements: iam.GetPolicyDocumentStatementArray{
			iam.GetPolicyDocumentStatementArgs{
				Actions: P_STR_ARR_STS_ASSUME_ROLE_WEB_IDENTITY,
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_STRING_EQUALS,
						Values:   P_STR_ARR_STS_AMAZONAWS_COM,
						Variable: pulumi.Sprintf("%s:aud", l.oidcProviderURL),
					},
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_STRING_EQUALS,
						Values:   pulumi.ToStringArray([]string{"system:serviceaccount:kube-system:" + LB_CONTROLLER_NAME}),
						Variable: pulumi.Sprintf("%s:sub", l.oidcProviderURL),
					},
				},
				Effect: P_STR_ALLOW,
				Principals: iam.GetPolicyDocumentStatementPrincipalArray{
					iam.GetPolicyDocumentStatementPrincipalArgs{
						Type:        P_STR_FEDERATED,
						Identifiers: pulumi.ToStringArray([]string{l.oidcProviderARN}),
					},
				},
			},
		},
	})

	name := fmt.Sprintf("%s-lb-controller", l.baseName)
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
					"iam:CreateServiceLinkedRole",
				}),
				Effect:    P_STR_ALLOW,
				Resources: P_STR_ARR_WILDCARD,
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_STRING_EQUALS,
						Variable: pulumi.String("iam:AWSServiceName"),
						Values:   P_STR_ARR_ELB_AMAZONAWS_COM,
					},
				},
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"elasticloadbalancing:DescribeTargetHealth",
					"elasticloadbalancing:DescribeTargetGroups",
					"elasticloadbalancing:DescribeTargetGroupAttributes",
					"elasticloadbalancing:DescribeTags",
					"elasticloadbalancing:DescribeSSLPolicies",
					"elasticloadbalancing:DescribeRules",
					"elasticloadbalancing:DescribeLoadBalancers",
					"elasticloadbalancing:DescribeLoadBalancerAttributes",
					"elasticloadbalancing:DescribeListeners",
					"elasticloadbalancing:DescribeListenerCertificates",
					"ec2:GetCoipPoolUsage",
					"ec2:DescribeVpcs",
					"ec2:DescribeVpcPeeringConnections",
					"ec2:DescribeTags",
					"ec2:DescribeSubnets",
					"ec2:DescribeSecurityGroups",
					"ec2:DescribeNetworkInterfaces",
					"ec2:DescribeInternetGateways",
					"ec2:DescribeInstances",
					"ec2:DescribeCoipPools",
					"ec2:DescribeAvailabilityZones",
					"ec2:DescribeAddresses",
					"ec2:DescribeAccountAttributes",
				}),
				Effect:    P_STR_ALLOW,
				Resources: P_STR_ARR_WILDCARD,
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"wafv2:GetWebACLForResource",
					"wafv2:GetWebACL",
					"wafv2:DisassociateWebACL",
					"wafv2:AssociateWebACL",
					"waf-regional:GetWebACLForResource",
					"waf-regional:GetWebACL",
					"waf-regional:DisassociateWebACL",
					"waf-regional:AssociateWebACL",
					"shield:GetSubscriptionState",
					"shield:DescribeProtection",
					"shield:DeleteProtection",
					"shield:CreateProtection",
					"iam:ListServerCertificates",
					"iam:GetServerCertificate",
					"cognito-idp:DescribeUserPoolClient",
					"acm:ListCertificates",
					"acm:DescribeCertificate",
				}),
				Effect:    P_STR_ALLOW,
				Resources: P_STR_ARR_WILDCARD,
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"ec2:RevokeSecurityGroupIngress",
					"ec2:CreateSecurityGroup",
					"ec2:AuthorizeSecurityGroupIngress",
				}),
				Effect:    P_STR_ALLOW,
				Resources: P_STR_ARR_WILDCARD,
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"ec2:CreateTags",
				}),
				Effect:    P_STR_ALLOW,
				Resources: pulumi.ToStringArray([]string{"arn:aws:ec2:*:*:security-group/*"}),
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_NULL,
						Variable: pulumi.String("aws:RequestTag/elbv2.k8s.aws/cluster"),
						Values:   P_STR_ARR_FALSE,
					},
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_STRING_EQUALS,
						Variable: pulumi.String("ec2:CreateAction"),
						Values:   pulumi.ToStringArray([]string{"CreateSecurityGroup"}),
					},
				},
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"ec2:DeleteTags",
					"ec2:CreateTags",
				}),
				Effect:    P_STR_ALLOW,
				Resources: pulumi.ToStringArray([]string{"arn:aws:ec2:*:*:security-group/*"}),
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_NULL,
						Variable: pulumi.String("aws:RequestTag/elbv2.k8s.aws/cluster"),
						Values:   P_STR_ARR_TRUE,
					},
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_NULL,
						Variable: pulumi.String("aws:ResourceTag/elbv2.k8s.aws/cluster"),
						Values:   P_STR_ARR_FALSE,
					},
				},
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"ec2:RevokeSecurityGroupIngress",
					"ec2:DeleteSecurityGroup",
					"ec2:AuthorizeSecurityGroupIngress",
				}),
				Effect:    P_STR_ALLOW,
				Resources: P_STR_ARR_WILDCARD,
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_NULL,
						Variable: pulumi.String("aws:ResourceTag/elbv2.k8s.aws/cluster"),
						Values:   P_STR_ARR_FALSE,
					},
				},
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"elasticloadbalancing:CreateTargetGroup",
					"elasticloadbalancing:CreateLoadBalancer",
					"elasticloadbalancing:AddTags",
				}),
				Effect:    P_STR_ALLOW,
				Resources: P_STR_ARR_WILDCARD,
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_NULL,
						Variable: pulumi.String("aws:RequestTag/elbv2.k8s.aws/cluster"),
						Values:   P_STR_ARR_FALSE,
					},
				},
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"elasticloadbalancing:DeleteRule",
					"elasticloadbalancing:DeleteListener",
					"elasticloadbalancing:CreateRule",
					"elasticloadbalancing:CreateListener",
					"elasticloadbalancing:AddTags",
				}),
				Effect:    P_STR_ALLOW,
				Resources: P_STR_ARR_WILDCARD,
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"elasticloadbalancing:RemoveTags",
					"elasticloadbalancing:AddTags",
				}),
				Effect: P_STR_ALLOW,
				Resources: pulumi.ToStringArray([]string{
					"arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
					"arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
					"arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*",
				}),
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_NULL,
						Variable: pulumi.String("aws:RequestTag/elbv2.k8s.aws/cluster"),
						Values:   P_STR_ARR_TRUE,
					},
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_NULL,
						Variable: pulumi.String("aws:ResourceTag/elbv2.k8s.aws/cluster"),
						Values:   P_STR_ARR_FALSE,
					},
				},
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"elasticloadbalancing:RemoveTags",
					"elasticloadbalancing:AddTags",
				}),
				Effect: P_STR_ALLOW,
				Resources: pulumi.ToStringArray([]string{
					"arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
					"arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
					"arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
					"arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*",
				}),
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"elasticloadbalancing:SetSubnets",
					"elasticloadbalancing:SetSecurityGroups",
					"elasticloadbalancing:SetIpAddressType",
					"elasticloadbalancing:ModifyTargetGroupAttributes",
					"elasticloadbalancing:ModifyTargetGroup",
					"elasticloadbalancing:ModifyLoadBalancerAttributes",
					"elasticloadbalancing:DeleteTargetGroup",
					"elasticloadbalancing:DeleteLoadBalancer",
				}),
				Effect:    P_STR_ALLOW,
				Resources: P_STR_ARR_WILDCARD,
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_NULL,
						Variable: pulumi.String("aws:ResourceTag/elbv2.k8s.aws/cluster"),
						Values:   P_STR_ARR_FALSE,
					},
				},
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"elasticloadbalancing:AddTags",
				}),
				Effect: P_STR_ALLOW,
				Resources: pulumi.ToStringArray([]string{
					"arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
					"arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
					"arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*",
				}),
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_NULL,
						Variable: pulumi.String("aws:RequestTag/elbv2.k8s.aws/cluster"),
						Values:   P_STR_ARR_FALSE,
					},
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_STRING_EQUALS,
						Variable: pulumi.String("elasticloadbalancing:CreateAction"),
						Values: pulumi.ToStringArray([]string{
							"CreateTargetGroup",
							"CreateLoadBalancer",
						}),
					},
				},
			},

			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"elasticloadbalancing:RegisterTargets",
					"elasticloadbalancing:DeregisterTargets",
				}),
				Effect:    P_STR_ALLOW,
				Resources: pulumi.ToStringArray([]string{"arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"}),
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"elasticloadbalancing:SetWebAcl",
					"elasticloadbalancing:RemoveListenerCertificates",
					"elasticloadbalancing:ModifyRule",
					"elasticloadbalancing:ModifyListener",
					"elasticloadbalancing:AddListenerCertificates",
				}),
				Effect:    P_STR_ALLOW,
				Resources: P_STR_ARR_WILDCARD,
			},
		},
	})

	l.roles["lbController"] = role

	_, err = iam.NewRolePolicy(ctx, name, &iam.RolePolicyArgs{
		Role:   role.Name,
		Policy: policy.Json(),
	})
	if err != nil {
		return err
	}

	return nil
}

func (l *rolesConfig) karpenterNodeRole(ctx *pulumi.Context) error {
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

	name := fmt.Sprintf("%s-%s-node", l.baseName, KARPENTER_NAME)
	role, err := iam.NewRole(ctx, name, &iam.RoleArgs{
		AssumeRolePolicy: assumeRole.Json(),
	})
	if err != nil {
		return err
	}

	l.roles["karpenterNode"] = role

	for _, policyName := range []string{
		"AmazonSSMManagedInstanceCore",
		"AmazonEKS_CNI_Policy",
		"AmazonEC2ContainerRegistryReadOnly",
		"AmazonEKSWorkerNodePolicy",
	} {
		policy, err := iam.LookupPolicy(ctx, &iam.LookupPolicyArgs{Name: pulumi.StringRef(policyName)})
		if err != nil {
			return err
		}

		attName := fmt.Sprintf("%s-%s", name, policyName)
		_, err = iam.NewRolePolicyAttachment(ctx, attName, &iam.RolePolicyAttachmentArgs{
			PolicyArn: pulumi.String(policy.Arn),
			Role:      role.Name,
		})
		if err != nil {
			return err
		}
	}

	return nil
}

func (l *rolesConfig) karpenterServiceRole(ctx *pulumi.Context) error {
	id, err := aws.GetCallerIdentity(ctx, nil)
	if err != nil {
		return err
	}

	assumeRole := iam.GetPolicyDocumentOutput(ctx, iam.GetPolicyDocumentOutputArgs{
		Statements: iam.GetPolicyDocumentStatementArray{
			iam.GetPolicyDocumentStatementArgs{
				Actions: P_STR_ARR_STS_ASSUME_ROLE_WEB_IDENTITY,
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_STRING_EQUALS,
						Values:   P_STR_ARR_STS_AMAZONAWS_COM,
						Variable: pulumi.Sprintf("%s:aud", l.oidcProviderURL),
					},
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_STRING_EQUALS,
						Values:   pulumi.ToStringArray([]string{fmt.Sprintf("system:serviceaccount:%[1]s:%[1]s", KARPENTER_NAME)}),
						Variable: pulumi.Sprintf("%s:sub", l.oidcProviderURL),
					},
				},
				Effect: P_STR_ALLOW,
				Principals: iam.GetPolicyDocumentStatementPrincipalArray{
					iam.GetPolicyDocumentStatementPrincipalArgs{
						Type:        P_STR_FEDERATED,
						Identifiers: pulumi.ToStringArray([]string{l.oidcProviderARN}),
					},
				},
			},
		},
	})

	name := fmt.Sprintf("%s-%s-service", l.baseName, KARPENTER_NAME)
	role, err := iam.NewRole(ctx, name, &iam.RoleArgs{
		AssumeRolePolicy: assumeRole.Json(),
	})
	if err != nil {
		return err
	}

	l.roles["karpenterService"] = role

	policy := iam.GetPolicyDocumentOutput(ctx, iam.GetPolicyDocumentOutputArgs{
		Statements: iam.GetPolicyDocumentStatementArray{
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"pricing:GetProducts",
					"ec2:DescribeSubnets",
					"ec2:DescribeSpotPriceHistory",
					"ec2:DescribeSecurityGroups",
					"ec2:DescribeLaunchTemplates",
					"ec2:DescribeInstances",
					"ec2:DescribeInstanceTypes",
					"ec2:DescribeInstanceTypeOfferings",
					"ec2:DescribeImages",
					"ec2:DescribeAvailabilityZones",
					"ec2:CreateTags",
					"ec2:CreateLaunchTemplate",
					"ec2:CreateFleet",
				}),
				Effect:    P_STR_ALLOW,
				Resources: P_STR_ARR_WILDCARD,
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"ec2:TerminateInstances",
					"ec2:DeleteLaunchTemplate",
				}),
				Effect:    P_STR_ALLOW,
				Resources: P_STR_ARR_WILDCARD,
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_STRING_EQUALS,
						Variable: pulumi.String("ec2:ResourceTag/karpenter.sh/discovery"),
						Values:   pulumi.ToStringArray([]string{l.baseName}),
					},
				},
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"ec2:RunInstances",
				}),
				Effect: P_STR_ALLOW,
				Resources: pulumi.ToStringArray([]string{
					fmt.Sprintf("arn:aws:ec2:*:%s:launch-template/*", id.AccountId),
				}),
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_STRING_EQUALS,
						Variable: pulumi.String("ec2:ResourceTag/karpenter.sh/discovery"),
						Values:   pulumi.ToStringArray([]string{l.baseName}),
					},
				},
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"ec2:RunInstances",
				}),
				Effect: P_STR_ALLOW,
				Resources: pulumi.ToStringArray([]string{
					"arn:aws:ec2:*::snapshot/*",
					"arn:aws:ec2:*::image/*",
					fmt.Sprintf("arn:aws:ec2:*:%s:volume/*", id.AccountId),
					fmt.Sprintf("arn:aws:ec2:*:%s:subnet/*", id.AccountId),
					fmt.Sprintf("arn:aws:ec2:*:%s:spot-instances-request/*", id.AccountId),
					fmt.Sprintf("arn:aws:ec2:*:%s:security-group/*", id.AccountId),
					fmt.Sprintf("arn:aws:ec2:*:%s:network-interface/*", id.AccountId),
					fmt.Sprintf("arn:aws:ec2:*:%s:instance/*", id.AccountId),
				}),
			},

			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"ssm:GetParameter",
				}),
				Effect:    P_STR_ALLOW,
				Resources: pulumi.ToStringArray([]string{"arn:aws:ssm:*:*:parameter/aws/service/*"}),
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"eks:DescribeCluster",
				}),
				Effect:    P_STR_ALLOW,
				Resources: pulumi.ToStringArray([]string{l.clusterARN}),
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"iam:PassRole",
				}),
				Effect:    P_STR_ALLOW,
				Resources: pulumi.ToStringArrayOutput([]pulumi.StringOutput{l.roles["karpenterNode"].Arn}),
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"iam:TagInstanceProfile",
					"iam:RemoveRoleFromInstanceProfile",
					"iam:GetInstanceProfile",
					"iam:DeleteInstanceProfile",
					"iam:CreateInstanceProfile",
					"iam:AddRoleToInstanceProfile",
				}),
				Effect:    P_STR_ALLOW,
				Resources: P_STR_ARR_WILDCARD,
			},

			//         {
			//             "Action": [
			//                 "sqs:ReceiveMessage",
			//                 "sqs:GetQueueUrl",
			//                 "sqs:GetQueueAttributes",
			//                 "sqs:DeleteMessage"
			//             ],
			//             "Effect": "Allow",
			//             "Resource": "arn:aws:sqs:us-east-1:037532365270:Karpenter-jdt"
			//         },

		},
	})

	_, err = iam.NewRolePolicy(ctx, name, &iam.RolePolicyArgs{
		Role:   role.Name,
		Policy: policy.Json(),
	})
	if err != nil {
		return err
	}

	return nil
}
