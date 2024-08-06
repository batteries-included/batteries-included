package kube

import (
	"bi/pkg/access"
	"context"
	"fmt"
	"log/slog"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

const controlServerInfoConfigMapName = "access-info"

func (batteryKube *batteryKubeClient) GetAccessInfo(ctx context.Context, namespace string) (*access.AccessSpec, error) {
	slog.Debug("Getting control access info", slog.String("namespace", namespace), slog.String("configMap", controlServerInfoConfigMapName))
	config, err := batteryKube.client.CoreV1().ConfigMaps(namespace).Get(ctx, controlServerInfoConfigMapName, metav1.GetOptions{})
	if err != nil {
		return nil, err
	}

	accessSpec, err := access.NewFromConfigMap(config)
	if err != nil {
		return nil, err
	}

	return accessSpec, nil
}

func (batteryKube *batteryKubeClient) GetPostgresAccessInfo(ctx context.Context, namespace string, clusterName string, userName string) (*access.PostgresAccessSpec, error) {
	secretName := potgresSecretName(clusterName, userName)
	slog.Debug("Getting postgres access info", slog.String("namespace", namespace), slog.String("secret", secretName))

	secret, err := batteryKube.client.CoreV1().Secrets(namespace).Get(ctx, secretName, metav1.GetOptions{})
	if err != nil {
		return nil, fmt.Errorf("failed to get postgres secret: %w", err)
	}
	postgresAccessSpec, err := access.NewPostgresAccessSpecFromSecret(secret)
	if err != nil {
		return nil, fmt.Errorf("failed to get postgres secret: %w", err)
	}
	return postgresAccessSpec, nil
}

func potgresSecretName(clusterName string, userName string) string {
	return fmt.Sprintf("cloudnative-pg.pg-%s.%s", clusterName, userName)
}
