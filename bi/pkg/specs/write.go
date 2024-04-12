package specs

import (
	"encoding/json"
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
		return err
	}

	os.MkdirAll(path.Base(filePath), 0o700)

	contents, err := json.Marshal(spec)
	if err != nil {
		return err
	}
	os.WriteFile(filePath, contents, 0o600)

	return nil
}