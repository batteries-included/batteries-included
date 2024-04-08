package specs

import (
	"os"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestUnmarshalJSON(t *testing.T) {
	t.Run("Success", func(t *testing.T) {
		data, err := os.ReadFile("testdata/install_spec.json")
		require.NoError(t, err)

		_, err = UnmarshalJSON(data)
		require.NoError(t, err)
	})

	t.Run("Fail", func(t *testing.T) {
		_, err := UnmarshalJSON([]byte(`{}`))
		require.Error(t, err)
	})
}
