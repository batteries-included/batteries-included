/*
Copyright © 2024 Elliott Clark
*/
package main

import (
	"bi/cmd"
	_ "bi/cmd/aws"
	_ "bi/cmd/debug"
	_ "bi/cmd/local"
	_ "bi/cmd/postgres"
	_ "bi/cmd/vpn"
)

func main() {
	cmd.Execute()
}
