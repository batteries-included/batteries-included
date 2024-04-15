package util

import (
	"context"
	"encoding/base64"
	"fmt"
	"net/http"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	v4 "github.com/aws/aws-sdk-go-v2/aws/signer/v4"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sts"
)

// GetToken returns a token that can be used to authenticate to an EKS cluster.
// This is equivalent to running `aws eks get-token --cluster-name <clusterName>`
// but without the need for the AWS CLI to be installed.
func GetToken(ctx context.Context, clusterName string, ttl time.Duration) (string, error) {
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return "", fmt.Errorf("failed to load AWS config: %w", err)
	}

	stsclient := sts.NewFromConfig(cfg)
	presignclient := sts.NewPresignClient(stsclient)

	out, err := presignclient.PresignGetCallerIdentity(ctx, &sts.GetCallerIdentityInput{}, func(opt *sts.PresignOptions) {
		opt.Presigner = &presignerV4{
			client:      opt.Presigner,
			clusterName: clusterName,
			ttl:         ttl,
		}
	})
	if err != nil {
		return "", fmt.Errorf("failed to presign GetCallerIdentity: %w", err)
	}

	return fmt.Sprintf("k8s-aws-v1.%s", base64.RawStdEncoding.EncodeToString([]byte(out.URL))), nil
}

var (
	_ sts.HTTPPresignerV4 = (*presignerV4)(nil)
)

type presignerV4 struct {
	client      sts.HTTPPresignerV4
	clusterName string
	ttl         time.Duration
}

func (p *presignerV4) PresignHTTP(
	ctx context.Context, credentials aws.Credentials, r *http.Request,
	payloadHash string, service string, region string, signingTime time.Time,
	optFns ...func(*v4.SignerOptions),
) (url string, signedHeader http.Header, err error) {
	r.Header.Set("X-K8s-Aws-Id", p.clusterName)
	r.Header.Set("X-Amz-Expires", fmt.Sprintf("%d", int(p.ttl.Seconds())))

	return p.client.PresignHTTP(ctx, credentials, r, payloadHash, service, region, signingTime, optFns...)
}
