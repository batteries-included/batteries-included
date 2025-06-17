package registry

import (
	"bytes"
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

// registryImpl implements the Registry interface using a map
type registryImpl struct {
	records map[string]ImageRecord
}

// NewRegistry creates a new empty registry
func NewRegistry() Registry {
	return &registryImpl{
		records: make(map[string]ImageRecord),
	}
}

// Read loads a registry from a YAML file
func Read(filePath string) (Registry, error) {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read registry file: %w", err)
	}

	records := make(map[string]ImageRecord)
	if err := yaml.Unmarshal(data, &records); err != nil {
		return nil, fmt.Errorf("failed to parse registry YAML: %w", err)
	}

	// Validate all records
	for name, record := range records {
		if err := record.Validate(); err != nil {
			return nil, fmt.Errorf("invalid record for %q: %w", name, err)
		}
	}

	return &registryImpl{records: records}, nil
}

// Write saves the registry to a YAML file
func (r *registryImpl) Write(filePath string) error {
	// Validate all records before writing
	for name, record := range r.records {
		if err := record.Validate(); err != nil {
			return fmt.Errorf("invalid record for %q: %w", name, err)
		}
	}

	buf := bytes.Buffer{}
	enc := yaml.NewEncoder(&buf)
	enc.SetIndent(2) // Match the formatter config
	if err := enc.Encode(&r.records); err != nil {
		return fmt.Errorf("failed to marshal registry to YAML: %w", err)
	}
	data := buf.Bytes()

	if err := os.WriteFile(filePath, data, 0644); err != nil {
		return fmt.Errorf("failed to write registry file: %w", err)
	}

	return nil
}

// Set adds or updates an image record in the registry
func (r *registryImpl) Set(name string, record ImageRecord) error {
	if err := record.Validate(); err != nil {
		return fmt.Errorf("invalid record: %w", err)
	}
	r.records[name] = record
	return nil
}

// Get retrieves an image record from the registry
func (r *registryImpl) Get(name string) (ImageRecord, bool) {
	record, exists := r.records[name]
	return record, exists
}

// Delete removes an image record from the registry
func (r *registryImpl) Delete(name string) {
	delete(r.records, name)
}

// Exists checks if an image exists in the registry
func (r *registryImpl) Exists(name string) bool {
	_, exists := r.records[name]
	return exists
}

// Len returns the number of records in the registry
func (r *registryImpl) Len() int {
	return len(r.records)
}

// Records returns the underlying map of records for iteration
// This is used primarily for testing and internal operations
func (r *registryImpl) Records() map[string]ImageRecord {
	return r.records
}
