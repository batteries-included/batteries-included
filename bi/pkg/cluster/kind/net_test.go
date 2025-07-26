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
		{sub: "172.0.0.0/8", expected: "172.0.1.0/24", existing: 0},
		{sub: "172.0.0.0/8", expected: "172.0.2.0/24", existing: 1},
		{sub: "172.0.0.0/8", expected: "172.0.6.0/24", existing: 5},
		{sub: "172.18.0.0/16", expected: "172.18.1.0/24", existing: 0},
		{sub: "172.18.0.0/16", expected: "172.18.6.0/24", existing: 5},
		{sub: "172.18.1.0/24", expected: "172.18.1.32/27", existing: 0},
		{sub: "172.18.1.0/24", expected: "172.18.1.128/27", existing: 3},
		{sub: "172.18.1.1/26", expected: "172.18.1.8/29", existing: 0},
		{sub: "172.18.1.1/26", expected: "172.18.1.24/29", existing: 2},
		{sub: "172.18.1.1/26", expected: "172.18.1.32/29", existing: 3},
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
