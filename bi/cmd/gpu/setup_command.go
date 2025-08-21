package gpu

import (
	"bi/pkg/osutil"
	"bytes"
	_ "embed"
	"fmt"
	"log"
	"text/template"

	"github.com/spf13/cobra"
)

//go:embed scripts/setup_nvidia.sh
var setupNvidiaScript string

var setupCommandCmd = &cobra.Command{
	Use:   "setup-command",
	Short: "Generate a setup script for the NVIDIA Container Toolkit",
	Long: `Generates a shell script to install and configure the NVIDIA Container Toolkit.
The script is tailored to the detected Linux distribution.

You can run the output directly with bash:
sudo bash -c "$(bi gpu setup-command)"`,
	Run: func(cmd *cobra.Command, args []string) {
		distro := osutil.DetectLinuxDistribution()
		if distro == osutil.DistroUnknown {
			log.Fatal("Could not detect Linux distribution. This command is only supported on Debian, RHEL, and SUSE based systems.")
			return
		}

		data := struct {
			Distro string
		}{
			Distro: distro.String(),
		}

		tmpl, err := template.New("setup-script").Parse(setupNvidiaScript)
		if err != nil {
			log.Fatalf("Failed to parse setup script template: %v", err)
		}

		var script bytes.Buffer
		if err := tmpl.Execute(&script, data); err != nil {
			log.Fatalf("Failed to execute setup script template: %v", err)
		}

		fmt.Print(script.String())
	},
}

func init() {
	gpuCommand.AddCommand(setupCommandCmd)
}
