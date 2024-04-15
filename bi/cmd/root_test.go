package cmd

import (
	"bytes"
	"testing"

	"bi/pkg/testutil"
)

func Test_Example(t *testing.T) {
	// This doesn't need to be an integration test
	// It's more of a test to show that integration
	// testing is possible
	testutil.IntegrationTest(t)

	b := bytes.NewBufferString("")
	RootCmd.SetOut(b)
	RootCmd.SetArgs([]string{"-h"})
	if err := RootCmd.Execute(); err != nil {
		t.Error("Error running command", err)
	}

	if b.String() == "" {
		t.Error("No output")
	}
}
