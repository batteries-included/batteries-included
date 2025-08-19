package jwt

import (
	"crypto/x509"
	_ "embed"
	"encoding/json"
	"encoding/pem"
	"fmt"

	jose "github.com/go-jose/go-jose/v4"
)

// Embed the public keys
//
//go:embed keys/test.pub.pem
var testPublicKey []byte

//go:embed keys/home_a.pub.pem
var homeAPublicKey []byte

//go:embed keys/home_b.pub.pem
var homeBPublicKey []byte

// JWTResponse represents a response containing a JWT
type JWTResponse struct {
	JWT json.RawMessage `json:"jwt"`
}

// JWTVerifier handles JWT verification with different key configurations
type JWTVerifier struct {
	skipVerification bool
	publicKeys       [][]byte
}

// SkipVerification creates a JWTVerifier that skips signature verification
func SkipVerification() *JWTVerifier {
	return &JWTVerifier{
		skipVerification: true,
		publicKeys:       nil,
	}
}

// VerifyProd creates a JWTVerifier that only accepts production keys (home_a and home_b)
func VerifyProd() *JWTVerifier {
	return &JWTVerifier{
		skipVerification: false,
		publicKeys:       [][]byte{homeAPublicKey, homeBPublicKey},
	}
}

// VerifyTestOrProd creates a JWTVerifier that accepts test keys or production keys
func VerifyTestOrProd() *JWTVerifier {
	return &JWTVerifier{
		skipVerification: false,
		publicKeys:       [][]byte{testPublicKey, homeAPublicKey, homeBPublicKey},
	}
}

// NewVerifier creates a JWTVerifier based on the allowTestKeys flag
// If allowTestKeys is true, accepts both test and production keys
// If allowTestKeys is false, accepts only production keys
func NewVerifier(allowTestKeys bool) *JWTVerifier {
	if allowTestKeys {
		return VerifyTestOrProd()
	}
	return VerifyProd()
}

// ParseHomeBaseJWT parses a JWT response and extracts the payload with verification based on the verifier configuration
func (v *JWTVerifier) ParseHomeBaseJWT(responseBytes []byte) ([]byte, error) {
	jwtResp := &JWTResponse{}

	// Parse the response to extract the JWT
	err := json.Unmarshal(responseBytes, jwtResp)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal JWT response: %w", err)
	}

	// Remarshal the JWT back into a string for go-jose
	jwtBytes, err := jwtResp.JWT.MarshalJSON()
	if err != nil {
		return nil, fmt.Errorf("failed to marshal JWT back into string: %w", err)
	}

	// Parse the signed JWT
	jws, err := jose.ParseSigned(string(jwtBytes), []jose.SignatureAlgorithm{jose.ES256})
	if err != nil {
		return nil, fmt.Errorf("failed to parse signed JWT: %w", err)
	}

	// Extract payload with or without verification
	if v.skipVerification {
		return jws.UnsafePayloadWithoutVerification(), nil
	}

	return v.verifyAndExtractPayload(jws)
}

// verifyAndExtractPayload verifies the JWT signature against the configured keys and extracts the payload
func (v *JWTVerifier) verifyAndExtractPayload(jws *jose.JSONWebSignature) ([]byte, error) {
	var lastErr error

	// Try each configured public key
	for i, keyBytes := range v.publicKeys {
		// Parse the PEM-encoded public key
		block, _ := pem.Decode(keyBytes)
		if block == nil {
			lastErr = fmt.Errorf("failed to decode PEM block for key %d", i)
			continue
		}

		publicKey, err := x509.ParsePKIXPublicKey(block.Bytes)
		if err != nil {
			lastErr = fmt.Errorf("failed to parse public key %d: %w", i, err)
			continue
		}

		payload, err := jws.Verify(publicKey)
		if err != nil {
			lastErr = fmt.Errorf("verification failed with key %d: %w", i, err)
			continue
		}

		// Successfully verified
		return payload, nil
	}

	// If we get here, none of the keys worked
	if lastErr != nil {
		return nil, fmt.Errorf("JWT verification failed with all configured keys: %w", lastErr)
	}
	return nil, fmt.Errorf("no public keys configured for verification")
}
