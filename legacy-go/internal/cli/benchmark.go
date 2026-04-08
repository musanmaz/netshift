package cli

import (
	"fmt"
	"sort"
	"time"

	"dns-helper/internal/bench"
	"dns-helper/internal/resolvers"

	"github.com/spf13/cobra"
)

var domains []string
var runs int
var timeout time.Duration

func init() {
	cmd := &cobra.Command{
		Use:   "benchmark [profile|all]",
		Short: "DNS resolver latency comparison",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			targets := map[string][]string{}
			if args[0] == "all" {
				for k, v := range resolvers.Presets {
					targets[k] = v
				}
			} else {
				if ips, ok := resolvers.Presets[args[0]]; ok {
					targets[args[0]] = ips
				} else {
					return fmt.Errorf("profile not found: %s", args[0])
				}
			}
			results := bench.Run(targets, domains, runs, timeout)
			// print sorted results
			keys := make([]string, 0, len(results))
			for k := range results {
				keys = append(keys, k)
			}
			sort.Strings(keys)
			fmt.Printf("Benchmark (runs=%d, timeout=%s): %v\n", runs, timeout, domains)
			for _, name := range keys {
				r := results[name]
				fmt.Printf("- %-10s avg=%.1fms p50=%.1fms p90=%.1fms success=%d/%d\n",
					name, r.AvgMS(), r.P50MS(), r.P90MS(), r.Successes, r.Total)
			}
			return nil
		},
	}
	cmd.Flags().StringSliceVar(&domains, "domains", []string{"turk.net", "google.com", "cloudflare.com"}, "domains to test")
	cmd.Flags().IntVar(&runs, "runs", 5, "number of queries per domain")
	cmd.Flags().DurationVar(&timeout, "timeout", 1200*time.Millisecond, "single query timeout")
	rootCmd.AddCommand(cmd)
}
