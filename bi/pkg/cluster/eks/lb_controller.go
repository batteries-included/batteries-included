package eks

import (
	_ "embed"
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

var (
	//go:embed lb_controller_iam_policy.json
	iamPolicy string
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

	l.role = role

	_, err = iam.NewRolePolicy(ctx, name, &iam.RolePolicyArgs{
		Role:   role.Name,
		Policy: pulumi.String(iamPolicy),
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
