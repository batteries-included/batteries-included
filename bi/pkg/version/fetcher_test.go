package version

import (
	"bi/pkg/jwt"
	"testing"
	"time"
)

func TestNewVersionFetcher(t *testing.T) {
	t.Run("creates fetcher with defaults", func(t *testing.T) {
		fetcher := NewVersionFetcher()

		if fetcher.verifier == nil {
			t.Error("Expected verifier to be set")
		}

		if fetcher.client == nil {
			t.Error("Expected client to be set")
		}

		if fetcher.client.Timeout != 30*time.Second {
			t.Errorf("Expected timeout to be 30s, got %v", fetcher.client.Timeout)
		}
	})

	t.Run("applies options correctly", func(t *testing.T) {
		testVerifier := jwt.VerifyTestOrProd()
		fetcher := NewVersionFetcher(
			WithJWTVerifier(testVerifier),
		)

		if fetcher.verifier != testVerifier {
			t.Error("Expected test verifier to be set")
		}
	})
}
