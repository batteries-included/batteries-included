package kind

import (
	"fmt"
	"net"
	"testing"

	"github.com/stretchr/testify/require"
)

func Test_split(t *testing.T) {
	testCases := []struct {
		sub, expected string
		existing      int
		errExpected   bool
	}{
		{sub: "172.0.0.0/8", expected: "172.0.0.16/28", existing: 0},
		{sub: "172.0.0.0/8", expected: "172.0.0.32/28", existing: 1},
		{sub: "172.0.0.0/8", expected: "172.0.0.96/28", existing: 5},
		{sub: "172.18.0.0/16", expected: "172.18.0.16/28", existing: 0},
		{sub: "172.18.0.0/16", expected: "172.18.0.96/28", existing: 5},
		{sub: "172.18.1.0/24", expected: "172.18.1.16/28", existing: 0},
		{sub: "172.18.1.1/26", expected: "172.18.1.16/28", existing: 0},
		{sub: "172.18.1.1/26", expected: "", existing: 3, errExpected: true},
		{sub: "172.18.1.1/29", expected: "", existing: 0, errExpected: true},
		{sub: "172.18.1.1/32", expected: "", existing: 0, errExpected: true},
	}

	for _, tc := range testCases {
		t.Run(fmt.Sprintf("subnet: %s, existing: %d", tc.sub, tc.existing), func(t *testing.T) {
			_, ipnet, err := net.ParseCIDR(tc.sub)
			require.NoError(t, err)

			got, err := split(ipnet, tc.existing)
			if tc.errExpected {
				require.Error(t, err)
				return
			}

			require.NoError(t, err)
			require.Equal(t, tc.expected, got.String())
		})
	}
}
