package versions

import (
	"regexp"
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
	for i := 0; i < max(len(aParts), len(bParts)); i++ {
		var aPart, bPart int
		if i < len(aParts) {
			aPart = aParts[i]
		} else {
			aPart = 0 // If a has no more parts, treat as 0
		}
		if i < len(bParts) {
			bPart = bParts[i]
		} else {
			bPart = 0 // If b has no more parts, treat as 0
		}

		if aPart < bPart {
			return -1 // a is less than b
		} else if aPart > bPart {
			return 1 // a is greater than b
		}
	}

	return 0 // Versions are equal
}

// splitVersion splits a version string into its components
// removing any leading or trailing alphabetic characters and ensuring all parts are numeric.
// . and - are treated as delimiters.
var nonNumericRegex = regexp.MustCompile(`[^0-9.-]+`)

func splitVersion(version string) []int {
	// Replace '-' with '.' to treat them as the same delimiter
	version = strings.ReplaceAll(version, "-", ".")
	// Remove any alphabetic characters using a regex
	version = nonNumericRegex.ReplaceAllString(version, "")

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
