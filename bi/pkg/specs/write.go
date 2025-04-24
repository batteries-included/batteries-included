package specs

import (
	"encoding/json"
	"fmt"
	"os"
	"path"
)

func (spec *InstallSpec) WriteToPath(filePath string) error {
	_, err := os.Stat(filePath)
	// If the file exists then return assume it's okay and return nil for errors.
	if err == nil {
		return nil
	}
	// If there was an error and it wasn't because the file doesn't exist
	// then return the error
	if !os.IsNotExist(err) {
		return fmt.Errorf("unable to write install spec: %w", err)
	}

	if err := os.MkdirAll(path.Dir(filePath), 0o700); err != nil {
		return fmt.Errorf("unable to create install spec directory: %w", err)
	}

	contents, err := json.Marshal(spec)
	if err != nil {
		return fmt.Errorf("unable to marshal install spec: %w", err)
	}

	if err := os.WriteFile(filePath, contents, 0o600); err != nil {
		return fmt.Errorf("unable to write install spec: %w", err)
	}

	return nil
}
