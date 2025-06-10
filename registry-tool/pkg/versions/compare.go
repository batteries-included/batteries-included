package versions

import (
	"strconv"
	"strings"
)

// Compare compares two version strings and returns:
// -1 if a < b
//
//	1 if a > b
//	0 if a == b
func Compare(a, b string) int {
	// Split the versions into components
	aParts := splitVersion(a)
	bParts := splitVersion(b)

	// Compare each part of the version
	for i := 0; i < len(aParts) && i < len(bParts); i++ {
		if aParts[i] < bParts[i] {
			return -1
		} else if aParts[i] > bParts[i] {
			return 1
		}
	}

	// If one version has more parts, it is considered greater
	if len(aParts) < len(bParts) {
		return -1
	} else if len(aParts) > len(bParts) {
		return 1
	}

	return 0 // Versions are equal
}

// splitVersion splits a version string into its components
// removing any leading or trailing alphabetic characters and ensuring all parts are numeric.
// . and - are treated as delimiters.
func splitVersion(version string) []int {
	// Replace '-' with '.' to treat them as the same delimiter
	version = strings.ReplaceAll(version, "-", ".")

	// Split the version by '.' and convert to integers
	parts := strings.Split(version, ".")
	intParts := make([]int, 0, len(parts))

	for _, part := range parts {
		if num, err := strconv.Atoi(part); err == nil {
			intParts = append(intParts, num)
		} else {
			// If conversion fails, treat it as zero
			intParts = append(intParts, 0)
		}
	}

	return intParts
}
