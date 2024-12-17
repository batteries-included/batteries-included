package eks

import (
	"fmt"

	"bi/pkg/cluster/util"

	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/iam"
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/s3"
	"github.com/pulumi/pulumi/sdk/v3/go/auto"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

type cnpgConfig struct {
	// config
	baseName,
	namespace string

	// outputs
	oidcProviderURL,
	oidcProviderARN string

	// state
	role   *iam.Role
	bucket *s3.BucketV2
}

func (l *cnpgConfig) withConfig(cfg *util.PulumiConfig) error {
	l.baseName = cfg.Cluster.Name
	l.namespace = cfg.LBController.Namespace

	return nil
}

func (l *cnpgConfig) withOutputs(outputs map[string]auto.OutputMap) error {
	if outputs["cluster"]["oidcProviderURL"].Value != nil {
		l.oidcProviderURL = outputs["cluster"]["oidcProviderURL"].Value.(string)
	}

	if outputs["cluster"]["oidcProviderARN"].Value != nil {
		l.oidcProviderARN = outputs["cluster"]["oidcProviderARN"].Value.(string)
	}

	return nil
}

func (c *cnpgConfig) run(ctx *pulumi.Context) error {
	for _, fn := range []func(*pulumi.Context) error{
		c.backupBucket,
		c.buildCNPGRole,
	} {
		if err := fn(ctx); err != nil {
			return err
		}
	}

	ctx.Export("roleARN", c.role.Arn)
	ctx.Export("bucketARN", c.bucket.Arn)
	ctx.Export("bucketName", c.bucket.Bucket)

	return nil
}

func (c *cnpgConfig) backupBucket(ctx *pulumi.Context) error {
	bucket, err := s3.NewBucketV2(ctx, fmt.Sprintf("%s-pg-backup-bucket", c.baseName), &s3.BucketV2Args{
		BucketPrefix: pulumi.Sprintf("%s-pg-backup-", c.baseName),
		ForceDestroy: pulumi.Bool(true),
	})
	if err != nil {
		return fmt.Errorf("error creating backup bucket: %w", err)
	}

	_, err = s3.NewBucketServerSideEncryptionConfigurationV2(ctx, fmt.Sprintf("%s-pg-backup-server-side-enc-config", c.baseName), &s3.BucketServerSideEncryptionConfigurationV2Args{
		Bucket: bucket.ID(),
		Rules: s3.BucketServerSideEncryptionConfigurationV2RuleArray{
			&s3.BucketServerSideEncryptionConfigurationV2RuleArgs{
				ApplyServerSideEncryptionByDefault: &s3.BucketServerSideEncryptionConfigurationV2RuleApplyServerSideEncryptionByDefaultArgs{
					SseAlgorithm: pulumi.String("aws:kms"),
				},
				BucketKeyEnabled: pulumi.Bool(true),
			},
		},
	})
	if err != nil {
		return fmt.Errorf("error configuring backup bucket encryption: %w", err)
	}

	c.bucket = bucket

	return nil
}

func (c *cnpgConfig) buildCNPGRole(ctx *pulumi.Context) error {
	assumeRole := iam.GetPolicyDocumentOutput(ctx, iam.GetPolicyDocumentOutputArgs{
		Statements: iam.GetPolicyDocumentStatementArray{
			iam.GetPolicyDocumentStatementArgs{
				Actions: P_STR_ARR_STS_ASSUME_ROLE_WEB_IDENTITY,
				Conditions: iam.GetPolicyDocumentStatementConditionArray{
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_STRING_EQUALS,
						Values:   P_STR_ARR_STS_AMAZONAWS_COM,
						Variable: pulumi.Sprintf("%s:aud", c.oidcProviderURL),
					},
					iam.GetPolicyDocumentStatementConditionArgs{
						Test:     P_STR_STRING_LIKE,
						Values:   pulumi.ToStringArray([]string{"system:serviceaccount:*:pg-*"}),
						Variable: pulumi.Sprintf("%s:sub", c.oidcProviderURL),
					},
				},
				Effect: P_STR_ALLOW,
				Principals: iam.GetPolicyDocumentStatementPrincipalArray{
					iam.GetPolicyDocumentStatementPrincipalArgs{
						Type:        P_STR_FEDERATED,
						Identifiers: pulumi.ToStringArray([]string{c.oidcProviderARN}),
					},
				},
			},
		},
	})

	name := fmt.Sprintf("%s-pg-backup", c.baseName)
	role, err := iam.NewRole(ctx, name, &iam.RoleArgs{
		AssumeRolePolicy: assumeRole.Json(),
	})
	if err != nil {
		return fmt.Errorf("error registering IAM role %s: %w", name, err)
	}

	// TODO: restrict to specific prefixes so that
	// e.g. pg-controlserver serviceaccount can only access pg-controlserver prefix
	policy := iam.GetPolicyDocumentOutput(ctx, iam.GetPolicyDocumentOutputArgs{
		Statements: iam.GetPolicyDocumentStatementArray{
			iam.GetPolicyDocumentStatementArgs{
				Actions: pulumi.ToStringArray([]string{
					"s3:*",
				}),
				Effect: P_STR_ALLOW,
				Resources: pulumi.ToStringArrayOutput([]pulumi.StringOutput{
					c.bucket.Arn,
					pulumi.Sprintf("%s/*", c.bucket.Arn),
				}),
			},
		},
	})

	c.role = role

	_, err = iam.NewRolePolicy(ctx, name, &iam.RolePolicyArgs{
		Role:   role.Name,
		Policy: policy.Json(),
	})
	if err != nil {
		return fmt.Errorf("error registering IAM role policy %s: %w", name, err)
	}

	return nil
}
