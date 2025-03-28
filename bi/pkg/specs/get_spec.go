package specs

import (
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/url"
	"os"
	"strings"

	jose "github.com/go-jose/go-jose/v4"
)

func GetSpecFromURL(specURL string) (*InstallSpec, error) {
	// Parse the url
	parsedURL, err := url.Parse(specURL)
	if err != nil {
		return nil, fmt.Errorf("error parsing spec url: %w", err)
	}

	// If the url is a local file then read the
	// file and unmarshal the json using UnmarshalJSON
	// If the url is a remote file then download the
	// file and unmarshal the json using UnmarshalJSON
	if parsedURL.Scheme == "" {
		// Read the file
		return readLocalFile(parsedURL)
		// Only download on http for urls that string contrain 127.0.0.1
	} else if parsedURL.Scheme == "http" && (strings.Contains(parsedURL.Host, "127.0.0.1") || strings.Contains(parsedURL.Host, "127-0-0-1.batrsinc.co")) {
		// Download the file
		return readRemoteFile(parsedURL)
	} else if parsedURL.Scheme == "https" {
		// Download the file
		return readRemoteFile(parsedURL)
	} else {
		return nil, fmt.Errorf("unsupported scheme: %s", parsedURL.Scheme)
	}
}

func readLocalFile(parsedURL *url.URL) (*InstallSpec, error) {
	// Use the path from parsedURL Open the file
	// and read the contents
	// Unmarshal the json using UnmarshalJSON
	// returning the error if there is one
	slog.Debug("Reading local file", slog.String("path", parsedURL.Path))

	specBytes, err := os.ReadFile(parsedURL.Path)
	if err != nil {
		return nil, fmt.Errorf("error reading spec: %w", err)
	}

	installSpec, err := UnmarshalJSON(specBytes)
	if err != nil {
		return nil, fmt.Errorf("error unmarshalling spec: %w", err)
	}

	return &installSpec, nil
}

func readRemoteFile(parsedURL *url.URL) (*InstallSpec, error) {
	// Download the file
	slog.Debug("Downloading remote file", slog.String("url", parsedURL.String()))
	res, err := http.Get(parsedURL.String())
	if err != nil {
		return nil, fmt.Errorf("error downloading spec: %w", err)
	}

	specBytes, err := io.ReadAll(res.Body)
	if err != nil {
		return nil, fmt.Errorf("error reading spec: %w", err)
	}

	payload, err := parseSpecResponse(specBytes)
	if err != nil {
		return nil, fmt.Errorf("error parsing spec: %w", err)
	}

	installSpec, err := UnmarshalJSON(payload)
	if err != nil {
		return nil, fmt.Errorf("error unmarshalling spec: %w", err)
	}

	return &installSpec, nil
}

func parseSpecResponse(specBytes []byte) ([]byte, error) {
	type biJWT struct {
		JWS json.RawMessage `json:"jwt"`
	}
	jwt := &biJWT{}

	// we need the `jwt` key of the response. parse the whole thing first
	err := json.Unmarshal(specBytes, jwt)
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

	// TODO(jdt): actually verify
	return jws.UnsafePayloadWithoutVerification(), nil
}
