package main

import "dns-helper/internal/cli"

// Version information set during build
var (
	version   = "0.0.3"
	commit    = "unknown"
	buildTime = "unknown"
)

func main() {
	cli.Execute()
}
