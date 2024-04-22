package specs

import (
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/url"
	"os"
	"strings"
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
	} else if parsedURL.Scheme == "http" && strings.Contains(parsedURL.Host, "127.0.0.1") {
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
	res, err := http.Get(parsedURL.String())
	if err != nil {
		return nil, fmt.Errorf("error downloading spec: %w", err)
	}

	specBytes, err := io.ReadAll(res.Body)
	if err != nil {
		return nil, fmt.Errorf("error reading spec: %w", err)
	}

	installSpec, err := UnmarshalJSON(specBytes)
	if err != nil {
		return nil, fmt.Errorf("error unmarshalling spec: %w", err)
	}

	return &installSpec, nil
}
