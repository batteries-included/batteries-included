/*
Copyright © 2024 Elliott Clark
*/
package main

import (
	"bi/cmd"
	_ "bi/cmd/aws"
	_ "bi/cmd/debug"
	_ "bi/cmd/postgres"
)

func main() {
	cmd.Execute()
}
