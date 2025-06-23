package installs

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
)

func ListInstallations(ctx context.Context, fn func(*InstallEnv) error) error {
	// Read all directories in the base install path
	// For each directory, try and read the install spec
	// If it exists, call the function with the installation
	basePath := baseInstallPath()

	entries, err := os.ReadDir(basePath)
	if err != nil {
		return fmt.Errorf("error reading base install path %s: %w", basePath, err)
	}
	for _, entry := range entries {
		if !entry.IsDir() {
			slog.Warn("Skipping non-directory entry in base install path",
				slog.String("entry", entry.Name()))
			continue
		}

		slug := entry.Name()
		installPath := filepath.Join(basePath, slug)
		env, err := NewEnv(ctx, slug)
		if err != nil {
			slog.Warn("Error creating install environment",
				slog.String("slug", slug), slog.String("path", installPath), slog.Any("error", err))
			continue
		}
		if err := env.Init(ctx, false); err != nil {
			slog.Warn("Error initializing install environment",
				slog.String("slug", slug), slog.String("path", installPath), slog.Any("error", err))
			continue
		}

		if err := fn(env); err != nil {
			return err
		}
		slog.Debug("Listed installation",
			slog.String("slug", env.Slug),
			slog.String("path", installPath),
			slog.String("spec", env.SpecPath()),
			slog.String("summary", env.SummaryPath()),
			slog.String("kubeconfig", env.KubeConfigPath()),
			slog.String("wireguard", env.WireGuardConfigPath()))

	}
	return nil
}
