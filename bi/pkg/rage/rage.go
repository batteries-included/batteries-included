package rage

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"sort"

	"bi/pkg/installs"

	"github.com/mholt/archiver/v3"
)

func Rage(ctx context.Context, env *installs.InstallEnv, maxLogs int) error {
	debugLogDir := env.DebugLogDir()

	debugLogFiles, err := os.ReadDir(debugLogDir)
	if err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("failed to read debug logs directory: %w", err)
	}

	// Sort log directories by modification time, most recent first.
	sort.Slice(debugLogFiles, func(i, j int) bool {
		infoI, err := debugLogFiles[i].Info()
		if err != nil {
			slog.Warn("Failed to get info for debug log directory",
				slog.Any("error", err))
			return false
		}

		infoJ, err := debugLogFiles[j].Info()
		if err != nil {
			slog.Warn("Failed to get info for debug log directory",
				slog.Any("error", err))
			return false
		}

		return infoI.ModTime().After(infoJ.ModTime())
	})

	// Limit the number of logs to include in the archive.
	debugLogFiles = debugLogFiles[:min(len(debugLogFiles), maxLogs)]

	// Create a temporary zip archive file.
	zipFilePath := filepath.Join(os.TempDir(), fmt.Sprintf("bi-rage-%d.zip", os.Getpid()))

	// Collect the paths to the directories we want to archive.
	var pathsToArchive []string
	for _, file := range debugLogFiles {
		pathsToArchive = append(pathsToArchive, filepath.Join(debugLogDir, file.Name()))
	}

	// Create the zip archive.
	if err := archiver.Archive(pathsToArchive, zipFilePath); err != nil {
		return fmt.Errorf("failed to create zip archive: %w", err)
	}

	slog.Info("Rage complete", slog.String("zipFilePath", zipFilePath))

	return nil
}
