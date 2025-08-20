package specs

import (
	"bi/pkg/jwt"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/url"
	"os"
	"slices"
	"strings"
)

// SpecFetcher handles fetching and parsing installation specs with configurable JWT verification
type SpecFetcher struct {
	url                     string
	additionalInsecureHosts []string
	jwtVerifier             *jwt.JWTVerifier
}

// SpecFetcherOption configures the SpecFetcher
type SpecFetcherOption func(*SpecFetcher)

// WithURL sets the spec URL to fetch from
func WithURL(url string) SpecFetcherOption {
	return func(sf *SpecFetcher) {
		sf.url = url
	}
}

// WithAdditionalInsecureHosts sets additional hosts that are allowed over HTTP
func WithAdditionalInsecureHosts(hosts []string) SpecFetcherOption {
	return func(sf *SpecFetcher) {
		sf.additionalInsecureHosts = hosts
		// if sf.jwtVerifier is still prod then set it to jwt.VerifyTestOrProd
		if sf.jwtVerifier == jwt.VerifyProd() {
			sf.jwtVerifier = jwt.VerifyTestOrProd()
		}
	}
}

// WithJWTVerifier sets the JWT verifier to use for remote specs
func WithJWTVerifier(verifier *jwt.JWTVerifier) SpecFetcherOption {
	return func(sf *SpecFetcher) {
		sf.jwtVerifier = verifier
	}
}

// NewSpecFetcher creates a new SpecFetcher with the given options
func NewSpecFetcher(opts ...SpecFetcherOption) *SpecFetcher {
	sf := &SpecFetcher{
		additionalInsecureHosts: []string{},
		jwtVerifier:             jwt.VerifyProd(),
	}

	for _, opt := range opts {
		opt(sf)
	}

	return sf
}

// Fetch retrieves and parses the installation spec
func (sf *SpecFetcher) Fetch() (*InstallSpec, error) {
	return sf.fetchFromURL(sf.url)
}

// fetchFromURL retrieves and parses an installation spec from the given URL
func (sf *SpecFetcher) fetchFromURL(specURL string) (*InstallSpec, error) {
	parsedURL, err := url.Parse(specURL)
	if err != nil {
		return nil, fmt.Errorf("error parsing spec url: %w", err)
	}

	switch parsedURL.Scheme {
	case "":
		return sf.readLocalFile(parsedURL)
	case "https":
		return sf.readRemoteFile(parsedURL)
	case "http":
		if sf.allowInsecure(parsedURL) {
			return sf.readRemoteFile(parsedURL)
		}
		fallthrough

	default:
		return nil, fmt.Errorf("unsupported scheme: %s", parsedURL.Scheme)
	}
}

func (sf *SpecFetcher) allowInsecure(url *url.URL) bool {
	host := url.Host
	switch {

	// allow download on HTTP if home-base is running locally
	case strings.Contains(host, "127.0.0.1"):
		return true

	case strings.Contains(host, "127-0-0-1.batrsinc.co"):
		return true

	// or if user has allowed the specific host
	case slices.ContainsFunc(sf.additionalInsecureHosts, func(s string) bool {
		return strings.Contains(host, s)
	}):
		return true

	default:
		return false
	}
}

func (sf *SpecFetcher) readLocalFile(parsedURL *url.URL) (*InstallSpec, error) {
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

func (sf *SpecFetcher) readRemoteFile(parsedURL *url.URL) (*InstallSpec, error) {
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

	payload, err := sf.parseSpecResponse(specBytes)
	if err != nil {
		return nil, fmt.Errorf("error parsing spec: %w", err)
	}

	installSpec, err := UnmarshalJSON(payload)
	if err != nil {
		return nil, fmt.Errorf("error unmarshalling spec: %w", err)
	}

	return &installSpec, nil
}

func (sf *SpecFetcher) parseSpecResponse(specBytes []byte) ([]byte, error) {
	return sf.jwtVerifier.ParseHomeBaseJWT(specBytes)
}
