package kube

import (
	"bi/pkg/access"
	"context"
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
