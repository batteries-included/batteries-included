package versions

import (
	"sort"
)

func Sort(versions []string) {
	sort.Slice(versions, func(i, j int) bool {
		// Descending order comparison
		return Compare(versions[i], versions[j]) > 0
	})
}
