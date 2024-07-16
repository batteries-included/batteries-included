package util

import (
	"context"
	"encoding/base64"
	"fmt"
	"time"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sts"
	smithyhttp "github.com/aws/smithy-go/transport/http"
)

// GetToken returns a token that can be used to authenticate to an EKS cluster.
// This is equivalent to running `aws eks get-token --cluster-name <clusterName>`
// but without the need for the AWS CLI to be installed.
func GetToken(ctx context.Context, region, clusterName string, ttl time.Duration) (string, error) {
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(region))
	if err != nil {
		return "", fmt.Errorf("failed to load AWS config: %w", err)
	}

	client := sts.NewPresignClient(sts.NewFromConfig(cfg))

	presignedURLRequest, err := client.PresignGetCallerIdentity(ctx, &sts.GetCallerIdentityInput{}, func(presignOptions *sts.PresignOptions) {
		presignOptions.ClientOptions = append(presignOptions.ClientOptions, appendPresignHeaderValuesFunc(clusterName, ttl))
	})
	if err != nil {
		return "", fmt.Errorf("failed to presign caller identity: %w", err)
	}

	return fmt.Sprintf("k8s-aws-v1.%s", base64.RawURLEncoding.EncodeToString([]byte(presignedURLRequest.URL))), nil
}

func appendPresignHeaderValuesFunc(clusterName string, ttl time.Duration) func(stsOptions *sts.Options) {
	return func(stsOptions *sts.Options) {
		stsOptions.APIOptions = append(stsOptions.APIOptions,
			smithyhttp.SetHeaderValue("X-K8s-Aws-Id", clusterName),
			smithyhttp.SetHeaderValue("X-Amz-Expires", fmt.Sprintf("%d", int(ttl.Seconds()))),
		)
	}
}
