package cli

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var (
	version   = "0.0.3"
	commit    = "unknown"
	buildTime = "unknown"
)

var rootCmd = &cobra.Command{
	Use:     "dns-helper",
	Short:   "Switch and benchmark DNS resolvers locally",
	Long:    "DNS Helper: Switch DNS servers with a single command, show status, and run benchmarks.",
	Version: version,
}

func init() {
	rootCmd.AddCommand(&cobra.Command{
		Use:   "version",
		Short: "Show version information",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Printf("DNS Helper %s\n", version)
			fmt.Printf("Commit: %s\n", commit)
			fmt.Printf("Build Time: %s\n", buildTime)
		},
	})
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
