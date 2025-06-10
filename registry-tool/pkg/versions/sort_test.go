package versions

import (
	"reflect"
	"testing"
)

func TestCompare(t *testing.T) {
	tests := []struct {
		a, b     string
		expected int
	}{
		{"1.0.0", "1.0.0", 0},
		{"2.0.0", "1.0.0", 1},
		{"1.0.0", "2.0.0", -1},
		{"1.2.3", "1.2.3", 0},
		{"1.2.3", "1.2.4", -1},
		{"1.2.4", "1.2.3", 1},
		{"1.2", "1.2.0", 0},
		{"1.2.0.0", "1.2", 0},
		{"1.10.0", "1.2.0", 1},
		{"1.2-1", "1.2.1", 0},
		{"2", "1.9.9", 1},
		{"1.89.0", "2.0.0", -1},
		{"v1.89.0", "v2.0.0", -1},
		{"v1.89.0-test", "v2.0.0-test", -1},
		{"0.9.9", "1.0.0", -1},
		{"1.0.0", "1.0.0-1", -1},
	}

	for _, test := range tests {
		result := Compare(test.a, test.b)
		if result != test.expected {
			t.Errorf("Compare(%q, %q) = %d; want %d",
				test.a, test.b, result, test.expected)
		}
	}
}

func TestSort(t *testing.T) {
	tests := []struct {
		input    []string
		expected []string
	}{
		{
			input:    []string{"1.0.0", "2.0.0", "1.5.0"},
			expected: []string{"2.0.0", "1.5.0", "1.0.0"},
		},
		{
			input:    []string{"1.0.0", "1.0.1", "1.0.2"},
			expected: []string{"1.0.2", "1.0.1", "1.0.0"},
		},
		{
			input:    []string{"2.0", "1.0", "3.0"},
			expected: []string{"3.0", "2.0", "1.0"},
		},
		{
			input:    []string{"1.0.0", "1.0.0-1", "1.0"},
			expected: []string{"1.0.0-1", "1.0.0", "1.0"},
		},
	}

	for _, test := range tests {
		input := make([]string, len(test.input))
		copy(input, test.input)
		Sort(input)
		if !reflect.DeepEqual(input, test.expected) {
			t.Errorf("Sort(%v) = %v; want %v",
				test.input, input, test.expected)
		}
	}
}
