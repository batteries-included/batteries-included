package access

import (
	"encoding/json"
	"fmt"

	v1 "k8s.io/api/core/v1"
)

type AccessSpec struct {
	Hostname string         `json:"hostname"`
	SSL      StringableBool `json:"ssl"`
}

func (a *AccessSpec) PrintToConsole() error {
	// Display a clickable URL
	// If SSL is enabled, use https, otherwise use http
	protocol := "http"
	if a.SSL {
		protocol = "https"
	}
	// Just in case we add a new line here. Sometime ncurses doesn't remember what line it's on
	// and the progress bar will overwrite a line.
	_, err := fmt.Printf("Welcome to your Batteries Included platform: %s://%s\n", protocol, a.Hostname)
	if err != nil {
		return fmt.Errorf("failed to print control server URL: %w", err)
	}
	return nil
}
func NewFromConfigMap(config *v1.ConfigMap) (*AccessSpec, error) {
	// Round trip the data through JSON to ensure we're getting the correct types
	// and to avoid any potential issues with the unstructured data
	jsonBytes, err := json.Marshal(config.Data)
	if err != nil {
		return nil, err
	}

	accessSpec := &AccessSpec{}
	if err := json.Unmarshal(jsonBytes, accessSpec); err != nil {
		return nil, err
	}
	return accessSpec, nil
}
