package eks

import (
	"fmt"

	"bi/pkg/cluster/util"

	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/ec2"
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/iam"
	"github.com/pulumi/pulumi/sdk/v3/go/auto"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

const (
	LB_CONTROLLER_NAME = "aws-load-balancer-controller"
)

type lbControllerConfig struct {
	// config
	baseName,
	namespace string

	// outputs
	oidcProviderURL,
	oidcProviderARN string
	publicSubnetIDs []string

	// state
	role *iam.Role
	eips []pulumi.IDOutput
}

func (l *lbControllerConfig) withConfig(cfg *util.PulumiConfig) error {
	l.baseName = cfg.Cluster.Name
	l.namespace = cfg.LBController.Namespace

	return nil
}

func (l *lbControllerConfig) withOutputs(outputs map[string]auto.OutputMap) error {
	if outputs["cluster"]["oidcProviderURL"].Value != nil {
		l.oidcProviderURL = outputs["cluster"]["oidcProviderURL"].Value.(string)
	}

	if outputs["cluster"]["oidcProviderARN"].Value != nil {
		l.oidcProviderARN = outputs["cluster"]["oidcProviderARN"].Value.(string)
	}

	if outputs["vpc"]["publicSubnetIDs"].Value != nil {
		l.publicSubnetIDs = util.ToStringSlice(outputs["vpc"]["publicSubnetIDs"].Value)
	}

	return nil
}

func (l *lbControllerConfig) run(ctx *pulumi.Context) error {
	for _, fn := range []func(*pulumi.Context) error{
		l.buildLBControllerRole,
		l.buildIngressEIPs,
	} {
		if err := fn(ctx); err != nil {
			return err
		}
	}

	ctx.Export("roleARN", l.role.Arn)
	ctx.Export("eipAllocations", pulumi.ToIDArrayOutput(l.eips))

	return nil
}

func (l *lbControllerConfig) buildLBControllerRole(ctx *pulumi.Context) error {
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
						Values:   pulumi.ToStringArray([]string{util.ServiceAccount(l.namespace, LB_CONTROLLER_NAME)}),
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
		return fmt.Errorf("error registering IAM role %s: %w", name, err)
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

	l.role = role

	_, err = iam.NewRolePolicy(ctx, name, &iam.RolePolicyArgs{
		Role:   role.Name,
		Policy: policy.Json(),
	})
	if err != nil {
		return fmt.Errorf("error registering IAM role policy %s: %w", name, err)
	}

	return nil
}

func (l *lbControllerConfig) buildIngressEIPs(ctx *pulumi.Context) error {
	for i := range l.publicSubnetIDs {
		name := fmt.Sprintf("%s-ingress-eip-%d", l.baseName, i)

		eip, err := ec2.NewEip(ctx, name, &ec2.EipArgs{
			Tags: pulumi.StringMap{"Name": pulumi.Sprintf("%s-ingress", l.baseName)},
		})
		if err != nil {
			return err
		}

		l.eips = append(l.eips, eip.ID())
	}

	return nil
}
