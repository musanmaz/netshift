package cli

import (
	"fmt"
	"sort"

	"dns-helper/internal/resolvers"

	"github.com/spf13/cobra"
)

func init() {
	cmd := &cobra.Command{
		Use:   "list",
		Short: "List available DNS profiles",
		Run: func(cmd *cobra.Command, args []string) {
			names := make([]string, 0, len(resolvers.Presets))
			for k := range resolvers.Presets {
				names = append(names, k)
			}
			sort.Strings(names)
			for _, n := range names {
				fmt.Printf("- %-10s -> %v\n", n, resolvers.Presets[n])
			}
		},
	}
	rootCmd.AddCommand(cmd)
}
