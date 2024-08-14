package kind_test

import (
	"bi/pkg/cluster/kind"
	"bi/pkg/testutil"
	"context"
	"fmt"
	"os"
	"testing"

	"github.com/neilotoole/slogt"
	"github.com/stretchr/testify/require"
)

func TestKindClusterProvider(t *testing.T) {
	testutil.IntegrationTest(t)

	ctx := context.Background()
	logger := slogt.New(t)

	name := fmt.Sprintf("test-cluster-%d", os.Getpid())

	p := kind.NewClusterProvider(logger, name, false)

	require.NoError(t, p.Init(ctx))

	require.NoError(t, p.Create(ctx, nil))
	t.Cleanup(func() {
		require.NoError(t, p.Destroy(ctx, nil))
	})
}
