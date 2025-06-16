package local

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"

	jose "github.com/go-jose/go-jose/v4"
)

type Installation struct {
	ID   string `json:"id"`
	Slug string `json:"slug"`
}

func CreateNewLocalInstall(ctx context.Context, baseURL string) (*Installation, error) {
	// From base_url PUT to "/api/v1/installations/new_local" that will
	// return a new Install that can be used to start a local installation

	createURL := fmt.Sprintf("%s/api/v1/installations/new_local", baseURL)
	req, err := http.NewRequest(http.MethodPut, createURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer res.Body.Close()

	installBytes, err := io.ReadAll(res.Body)
	if err != nil {
		return nil, fmt.Errorf("error reading install: %w", err)
	}
	parsed, err := parseCreateResponse(installBytes)
	if err != nil {
		slog.Error("Failed to parse create response", slog.String("response", string(installBytes)), slog.Any("error", err))
		return nil, fmt.Errorf("failed to parse create response: %w", err)
	}
	slog.Debug("Parsed InstallSpec", slog.Any("install", parsed))

	return parsed, nil
}

func parseCreateResponse(installBytes []byte) (*Installation, error) {
	type biJWT struct {
		JWS json.RawMessage `json:"jwt"`
	}
	jwt := &biJWT{}
	// we need the `jwt` key of the response. parse the whole thing first
	err := json.Unmarshal(installBytes, jwt)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal into temporary structure: %w", err)
	}

	// remarshal back into a string for go-jose
	bs, err := jwt.JWS.MarshalJSON()
	if err != nil {
		return nil, fmt.Errorf("failed to marshal JWS back into string: %w", err)
	}

	jws, err := jose.ParseSigned(string(bs), []jose.SignatureAlgorithm{jose.ES256})
	if err != nil {
		return nil, fmt.Errorf("failed to parse signed payload: %w", err)
	}
	payload := jws.UnsafePayloadWithoutVerification()
	var install Installation
	if err := json.Unmarshal(payload, &install); err != nil {
		return nil, fmt.Errorf("failed to unmarshal install spec: %w", err)
	}

	return &install, nil
}
