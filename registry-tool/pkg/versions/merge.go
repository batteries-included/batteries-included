package versions

func MergeSortedUnique(existing, new []string) []string {
	// Create a map to track unique tags
	seen := make(map[string]bool)

	// Pre-allocate result slice
	result := make([]string, 0, len(existing)+len(new))

	// Add all existing tags
	for _, tag := range existing {
		if _, exists := seen[tag]; !exists {
			seen[tag] = true
			result = append(result, tag)
		}
	}

	// Add all new tags
	for _, tag := range new {
		if _, exists := seen[tag]; !exists {
			seen[tag] = true
			result = append(result, tag)
		}
	}

	// Sort all tags
	Sort(result)

	return result
}
