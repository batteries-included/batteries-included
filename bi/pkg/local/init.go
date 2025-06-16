package local

import (
	"bi/pkg/installs"
	"context"
	"fmt"
)

func InitLocalInstallEnv(ctx context.Context, install *Installation, baseURL string) (*installs.InstallEnv, error) {
	url := fmt.Sprintf("%s/api/v1/installations/%s/spec", baseURL, install.ID)

	env, err := installs.NewEnv(ctx, url)
	if err != nil {
		return nil, fmt.Errorf("error creating new install env: %w", err)
	}
	err = env.Init(ctx, true)
	if err != nil {
		return nil, fmt.Errorf("error initializing install env: %w", err)
	}

	return env, nil
}
