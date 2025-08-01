package kind

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"strings"
	"time"
)

// ControlServerChecker verifies that the control server is accessible
type ControlServerChecker struct {
	baseURL string
}

func NewControlServerChecker(baseURL string) *ControlServerChecker {
	return &ControlServerChecker{
		baseURL: baseURL,
	}
}

func (csc *ControlServerChecker) WaitForControlServer(ctx context.Context, timeout time.Duration) error {
	if strings.Contains(csc.baseURL, "localhost") {
		slog.Info("Skipping control server check for localhost - VPN connection required")
		return fmt.Errorf("localhost check skipped - VPN connection required")
	}
	
	slog.Info("Waiting for control server to become accessible", 
		slog.String("url", csc.baseURL),
		slog.Duration("timeout", timeout))
	
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	
	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()
	
	client := &http.Client{
		Timeout: 10 * time.Second,
	}
	
	for {
		select {
		case <-ctx.Done():
			return fmt.Errorf("timeout waiting for control server to become accessible")
		case <-ticker.C:
			if err := csc.checkControlServer(client); err != nil {
				slog.Debug("Control server not yet accessible", slog.String("error", err.Error()))
				continue
			}
			
			slog.Info("Control server is now accessible", slog.String("url", csc.baseURL))
			return nil
		}
	}
}

func (csc *ControlServerChecker) checkControlServer(client *http.Client) error {
	if strings.Contains(csc.baseURL, "localhost") {
		return fmt.Errorf("localhost check skipped - VPN connection required")
	}
	
	resp, err := client.Get(csc.baseURL + "/health")
	if err != nil {
		return fmt.Errorf("failed to connect to control server: %w", err)
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("control server returned status %d", resp.StatusCode)
	}
	
	return nil
}

// GetControlServerURL returns the URL where the control server should be accessible
func GetControlServerURL(runtimeInfo *ContainerRuntimeInfo) string {
	switch runtimeInfo.Runtime {
	case RuntimePodman:
		if runtimeInfo.HostIP != "localhost" {
			return fmt.Sprintf("http://%s", runtimeInfo.HostIP)
		}
		return "http://localhost"
	case RuntimeColima:
		if runtimeInfo.HostIP != "localhost" {
			return fmt.Sprintf("http://%s", runtimeInfo.HostIP)
		}
		return "http://localhost"
	case RuntimeDockerDesktop:
		return "http://localhost"
	default:
		return "http://localhost"
	}
}

func PrintWhenItWorksInstructions(runtimeInfo *ContainerRuntimeInfo, clusterName string) {
	fmt.Println("\nSUCCESS! Your Batteries Included cluster is ready!")
	fmt.Println(strings.Repeat("=", 60))
	
	controlServerURL := GetControlServerURL(runtimeInfo)
	
	fmt.Printf("\nControl server: %s\n", controlServerURL)
	fmt.Printf("Connect via VPN: bi vpn config -o wg0-%s.conf %s\n", clusterName, clusterName)
	fmt.Printf("For help: bi --help\n")
	fmt.Println(strings.Repeat("=", 60))
}
