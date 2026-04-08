package cli

import (
	"fmt"

	"dns-helper/internal/platform"

	"github.com/spf13/cobra"
)

func init() {
	cmd := &cobra.Command{
		Use:   "status",
		Short: "Show active DNS settings",
		RunE: func(cmd *cobra.Command, args []string) error {
			s, err := platform.Status()
			if err != nil {
				return err
			}
			for iface, servers := range s {
				fmt.Printf("%-15s -> %v\n", iface, servers)
			}
			return nil
		},
	}
	rootCmd.AddCommand(cmd)
}
