package specs

import (
	"testing"
)

func TestFailEasyUnmarshal(t *testing.T) {
	var _, error = UnmarshalJSON([]byte(`{}`))

	if error == nil {
		t.Errorf("Should have failed to parse")
	}
}
