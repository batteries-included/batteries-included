package specs

import (
	"fmt"
	"os"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestGetBatteryByType(t *testing.T) {
	t.Parallel()
	data, err := os.ReadFile("testdata/install_spec.json")
	require.NoError(t, err)

	spec, err := UnmarshalJSON(data)
	require.NoError(t, err)

	cases := []struct {
		typ string
		err error
	}{
		{typ: "battery_core", err: nil},
		{typ: "doesnotexist", err: fmt.Errorf("failed to find battery with type: doesnotexist")},
	}

	for _, tc := range cases {
		tc := tc
		t.Run(tc.typ, func(t *testing.T) {
			t.Parallel()
			b, err := spec.GetBatteryByType(tc.typ)

			require.Equal(t, tc.err, err)

			if tc.err == nil {
				require.NotEmpty(t, b)
			}
		})
	}
}

func TestGetBatteryConfigField(t *testing.T) {
	t.Parallel()
	data, err := os.ReadFile("testdata/install_spec.json")
	require.NoError(t, err)

	spec, err := UnmarshalJSON(data)
	require.NoError(t, err)

	cases := []struct {
		typ, field string
		expected   any
		err        error
	}{
		{typ: "battery_core", field: "core_namespace", expected: "battery-core", err: nil},
		{typ: "battery_core", field: "doesnt_exist", expected: nil, err: fmt.Errorf("no field doesnt_exist in config")},
	}

	for _, tc := range cases {
		tc := tc
		t.Run(tc.typ, func(t *testing.T) {
			t.Parallel()
			f, err := spec.GetBatteryConfigField(tc.typ, tc.field)

			require.Equal(t, tc.err, err)
			require.Equal(t, tc.expected, f)
		})
	}
}
