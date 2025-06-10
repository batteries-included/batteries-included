package registry

// RegistryReader defines the read operations for the registry
type RegistryReader interface {
	// Get retrieves an image record by name
	Get(name string) (ImageRecord, bool)
	// Exists checks if an image exists in the registry
	Exists(name string) bool
	// Len returns the number of records
	Len() int
	// Records returns all image records in the registry
	Records() map[string]ImageRecord
}

// RegistryWriter defines the write operations for the registry
type RegistryWriter interface {
	// Set adds or updates an image record
	Set(name string, record ImageRecord) error
	// Delete removes an image record
	Delete(name string)
	// Write saves the registry to disk
	Write(filePath string) error
}

// Registry combines read and write operations
type Registry interface {
	RegistryReader
	RegistryWriter
}
