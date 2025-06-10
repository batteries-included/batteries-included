package registry

import (
	"os"
	"path/filepath"
	"testing"
)

func TestRegistryOperations(t *testing.T) {
	registry := NewRegistry()

	// Test Set and Get
	record := ImageRecord{
		Name:       "test/image",
		DefaultTag: "1.0.0",
		Tags:       []string{"1.0.0", "2.0.0"},
		TagRegex:   `^\d+\.\d+\.\d+$`,
	}

	if err := registry.Set("test", record); err != nil {
		t.Errorf("Set() error = %v", err)
	}

	got, exists := registry.Get("test")
	if !exists {
		t.Error("Get() record should exist")
	}
	if got.Name != record.Name {
		t.Errorf("Get() = %v, want %v", got.Name, record.Name)
	}

	// Test Exists
	if !registry.Exists("test") {
		t.Error("Exists() should return true for existing record")
	}
	if registry.Exists("nonexistent") {
		t.Error("Exists() should return false for nonexistent record")
	}

	// Test Delete
	registry.Delete("test")
	if registry.Exists("test") {
		t.Error("Exists() should return false after Delete()")
	}

	// Test Len
	if registry.Len() != 0 {
		t.Errorf("Len() = %v, want 0", registry.Len())
	}
}

func TestRegistryReadWrite(t *testing.T) {
	// Create temp directory for test files
	tempDir, err := os.MkdirTemp("", "registry-test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	testFile := filepath.Join(tempDir, "test-registry.yaml")

	// Create test registry
	registry := NewRegistry()
	record := ImageRecord{
		Name:       "test/image",
		DefaultTag: "1.0.0",
		Tags:       []string{"1.0.0", "2.0.0"},
		TagRegex:   `^\d+\.\d+\.\d+$`,
	}

	if err := registry.Set("test", record); err != nil {
		t.Fatalf("Failed to set record: %v", err)
	}

	// Test Write
	if err := registry.Write(testFile); err != nil {
		t.Fatalf("Write() error = %v", err)
	}

	// Test Read
	loadedRegistry, err := Read(testFile)
	if err != nil {
		t.Fatalf("Read() error = %v", err)
	}

	if loadedRegistry.Len() != 1 {
		t.Errorf("Read() registry has %v records, want 1", loadedRegistry.Len())
	}

	loadedRecord, exists := loadedRegistry.Get("test")
	if !exists {
		t.Error("Read() record should exist")
	}
	if loadedRecord.Name != record.Name {
		t.Errorf("Read() record name = %v, want %v", loadedRecord.Name, record.Name)
	}
}
