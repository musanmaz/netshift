package cli

import (
	"errors"
	"fmt"

	"dns-helper/internal/platform"
	"dns-helper/internal/resolvers"

	"github.com/spf13/cobra"
)

var dryRun bool

func init() {
	cmd := &cobra.Command{
		Use:   "switch [profile|custom] [ip1 ip2 ...]",
		Short: "Apply DNS profile or switch to custom IPs",
		Args:  cobra.MinimumNArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			var servers []string
			if args[0] == "custom" {
				if len(args) < 2 {
					return errors.New("custom requires at least one IP address")
				}
				servers = args[1:]
			} else {
				p, ok := resolvers.Presets[args[0]]
				if !ok {
					return fmt.Errorf("unknown profile: %s (use 'dns-helper list' to see available profiles)", args[0])
				}
				servers = p
			}
			return platform.SwitchAll(servers, dryRun)
		},
	}
	cmd.Flags().BoolVar(&dryRun, "dry-run", false, "show what would happen without making changes")
	rootCmd.AddCommand(cmd)

	// Add reset command
	resetCmd := &cobra.Command{
		Use:   "reset",
		Short: "Reset DNS settings to DHCP defaults",
		RunE: func(cmd *cobra.Command, args []string) error {
			return platform.ResetToDHCP(dryRun)
		},
	}
	resetCmd.Flags().BoolVar(&dryRun, "dry-run", false, "show what would happen without making changes")
	rootCmd.AddCommand(resetCmd)
}
