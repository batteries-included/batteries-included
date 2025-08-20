package jwt

import (
	"testing"
)

func TestNewVerifier(t *testing.T) {
	t.Run("allowTestKeys=false creates production verifier", func(t *testing.T) {
		verifier := NewVerifier(false)
		prodVerifier := VerifyProd()

		// Compare the number of keys to ensure they're equivalent
		if len(verifier.publicKeys) != len(prodVerifier.publicKeys) {
			t.Errorf("Expected %d keys, got %d", len(prodVerifier.publicKeys), len(verifier.publicKeys))
		}

		if verifier.skipVerification != prodVerifier.skipVerification {
			t.Errorf("Expected skipVerification=%v, got %v", prodVerifier.skipVerification, verifier.skipVerification)
		}
	})

	t.Run("allowTestKeys=true creates test+prod verifier", func(t *testing.T) {
		verifier := NewVerifier(true)
		testProdVerifier := VerifyTestOrProd()

		// Compare the number of keys to ensure they're equivalent
		if len(verifier.publicKeys) != len(testProdVerifier.publicKeys) {
			t.Errorf("Expected %d keys, got %d", len(testProdVerifier.publicKeys), len(verifier.publicKeys))
		}

		if verifier.skipVerification != testProdVerifier.skipVerification {
			t.Errorf("Expected skipVerification=%v, got %v", testProdVerifier.skipVerification, verifier.skipVerification)
		}
	})
}
