package eks

import (
	"fmt"

	"bi/pkg/cluster/util"

	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws"
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/cloudwatch"
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/iam"
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/sqs"
	"github.com/pulumi/pulumi/sdk/v3/go/auto"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

const (
	KARPENTER_NAME = "karpenter"
)

type karpenterConfig struct {
	// config
	baseName string

	// outputs
	clusterARN,
	nodeRoleARN,
	oidcProviderURL,
	oidcProviderARN string

	// state
	role  *iam.Role
	queue *sqs.Queue
}

func (k *karpenterConfig) withConfig(cfg *util.PulumiConfig) error {
	k.baseName = cfg.Cluster.Name

	return nil
}

func (k *karpenterConfig) withOutputs(outputs map[string]auto.OutputMap) error {
	k.clusterARN = outputs["cluster"]["arn"].Value.(string)
	k.nodeRoleARN = outputs["cluster"]["arn"].Value.(string)
	k.oidcProviderURL = outputs["cluster"]["oidcProviderURL"].Value.(string)
	k.oidcProviderARN = outputs["cluster"]["oidcProviderARN"].Value.(string)
	return nil
}

func (k *karpenterConfig) run(ctx *pulumi.Context) error {
	for _, fn := range []func(*pulumi.Context) error{
		k.sqsQueue,
		k.sqsQueuePolicy,
		k.cloudwatchEvents,
		k.karpenterServiceRole,
	} {
		if err := fn(ctx); err != nil {
			return err
		}
	}

	ctx.Export("queueARN", k.queue.Arn)
	ctx.Export("roleARN", k.role.Arn)

	return nil
}

func (k *karpenterConfig) sqsQueue(ctx *pulumi.Context) error {
	q, err := sqs.NewQueue(ctx, k.baseName, &sqs.QueueArgs{
		MessageRetentionSeconds: pulumi.Int(300),
		Name:                    pulumi.Sprintf("%s-karpenter", k.baseName),
		SqsManagedSseEnabled:    P_BOOL_PTR_TRUE,
	})
	if err != nil {
		return err
	}

	k.queue = q
	return nil
}

func (k *karpenterConfig) sqsQueuePolicy(ctx *pulumi.Context) error {
	policy := iam.GetPolicyDocumentOutput(ctx, iam.GetPolicyDocumentOutputArgs{
		Statements: iam.GetPolicyDocumentStatementArray{
			iam.GetPolicyDocumentStatementArgs{
				Actions:   pulumi.ToStringArray([]string{"sqs:SendMessage"}),
				Resources: pulumi.ToStringArrayOutput([]pulumi.StringOutput{k.queue.Arn}),
				Principals: iam.GetPolicyDocumentStatementPrincipalArray{
					iam.GetPolicyDocumentStatementPrincipalArgs{
						Type:        P_STR_SERVICE,
						Identifiers: pulumi.ToStringArray([]string{"events.amazonaws.com", "sqs.amazonaws.com"}),
					},
				},
			},
		},
	})

	_, err := sqs.NewQueuePolicy(ctx, k.baseName, &sqs.QueuePolicyArgs{
		QueueUrl: k.queue.Url,
		Policy:   policy.Json(),
	})
	if err != nil {
		return err
	}
	return nil
}

type eventRule struct {
	description string
	pattern     *eventPattern
}

type eventPattern struct {
	Source     []string `json:"source"`
	DetailType []string `json:"detail-type"`
}

func (k *karpenterConfig) cloudwatchEvents(ctx *pulumi.Context) error {
	target := pulumi.String("karpenter-interruption-queue-target")

	for event, rule := range map[string]eventRule{
		"health-event": {
			description: "Karpenter interrupt - AWS Health Event",
			pattern:     &eventPattern{Source: []string{"aws.health"}, DetailType: []string{"AWS Health Event"}},
		},
		"spot-interrupt": {
			description: "Karpenter interrupt - EC2 spot instance interruption warning",
			pattern:     &eventPattern{Source: []string{"aws.ec2"}, DetailType: []string{"AWS Spot Instance Interruption Warning"}},
		},
		"instance-rebalance": {
			description: "Karpenter interrupt - EC2 instance rebalance recommendation",
			pattern:     &eventPattern{Source: []string{"aws.ec2"}, DetailType: []string{"AWS Instance Rebalance Recommendation"}},
		},
		"instance-state-change": {
			description: "Karpenter interrupt - EC2 instance state-change notification",
			pattern:     &eventPattern{Source: []string{"aws.ec2"}, DetailType: []string{"AWS Instance State-change Notification"}},
		},
	} {
		name := fmt.Sprintf("%s-karpenter-%s", k.baseName, event)
		r, err := cloudwatch.NewEventRule(ctx, name, &cloudwatch.EventRuleArgs{
			Description:  pulumi.String(rule.description),
			NamePrefix:   pulumi.String(name + "-"),
			EventPattern: pulumi.JSONMarshal(rule.pattern),
		})
		if err != nil {
			return err
		}

		_, err = cloudwatch.NewEventTarget(ctx, name, &cloudwatch.EventTargetArgs{
			Rule:     r.Name,
			TargetId: target,
			Arn:      k.queue.Arn,
		})
		if err != nil {
			return err
		}
	}
	return nil
}

func (k *karpenterConfig) karpenterServiceRole(ctx *pulumi.Context) error {
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
						Variable: pulumi.Sprintf("%s:aud", k.oidcProviderURL),
					},
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_STRING_EQUALS,
						Values:   pulumi.ToStringArray([]string{fmt.Sprintf("system:serviceaccount:%[1]s:%[1]s", KARPENTER_NAME)}),
						Variable: pulumi.Sprintf("%s:sub", k.oidcProviderURL),
					},
				},
				Effect: P_STR_ALLOW,
				Principals: iam.GetPolicyDocumentStatementPrincipalArray{
					iam.GetPolicyDocumentStatementPrincipalArgs{
						Type:        P_STR_FEDERATED,
						Identifiers: pulumi.ToStringArray([]string{k.oidcProviderARN}),
					},
				},
			},
		},
	})

	name := fmt.Sprintf("%s-%s-service", k.baseName, KARPENTER_NAME)
	role, err := iam.NewRole(ctx, name, &iam.RoleArgs{
		AssumeRolePolicy: assumeRole.Json(),
	})
	if err != nil {
		return err
	}

	k.role = role

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
						Values:   pulumi.ToStringArray([]string{k.baseName}),
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
						Values:   pulumi.ToStringArray([]string{k.baseName}),
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
				Resources: pulumi.ToStringArray([]string{k.clusterARN}),
			},
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"iam:PassRole",
				}),
				Effect:    P_STR_ALLOW,
				Resources: pulumi.ToStringArray([]string{k.nodeRoleARN}),
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
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"sqs:ReceiveMessage",
					"sqs:GetQueueUrl",
					"sqs:GetQueueAttributes",
					"sqs:DeleteMessage",
				}),
				Effect:    P_STR_ALLOW,
				Resources: pulumi.ToStringArrayOutput([]pulumi.StringOutput{k.queue.Arn}),
			},
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
