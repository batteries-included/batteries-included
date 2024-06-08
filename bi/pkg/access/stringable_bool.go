package access

import (
	"fmt"
	"strings"
)

// StringableBool is a boolean that can be unmarshalled from a string
// value of "true" or "false" or "1" or "0"
//
// This is useful for getting boolean values from kubernetes configmaps
// The keys and values of which must be strings
type StringableBool bool

func (bit *StringableBool) UnmarshalJSON(data []byte) error {
	withoutQuotes := strings.Trim(string(data), "\"")
	switch str := strings.ToLower(withoutQuotes); str {
	case "1":
		*bit = true
	case "true":
		*bit = true
	case "0":
		*bit = false
	case "false":
		*bit = false
	default:
		return fmt.Errorf("invalid boolean value: %s", str)
	}
	return nil
}
