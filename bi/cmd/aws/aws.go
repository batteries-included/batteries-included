/*
Copyright © 2024 Batteries Included
*/
package aws

import (
	"bi/cmd"

	"github.com/spf13/cobra"
)

var awsCmd = &cobra.Command{
	Use:   "aws",
	Short: "Commands for working with AWS Kubernetes clusters",
	Long: `AWS EKS is a managed Kubernetes service 
that makes it easy for you to run Kubernetes on AWS
without needing to install, operate, and maintain 
your own Kubernetes control plane or nodes.`,
}

func init() {
	cmd.RootCmd.AddCommand(awsCmd)
}
