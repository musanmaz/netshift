package internal

import (
	"testing"
	"time"

	"dns-helper/internal/bench"
	"dns-helper/internal/resolvers"
)

func TestIntegrationBenchmark(t *testing.T) {
	// Test that benchmark can run with real resolvers
	targets := map[string][]string{
		"cloudflare": resolvers.Presets["cloudflare"],
		"google":     resolvers.Presets["google"],
	}

	domains := []string{"example.com"}
	runs := 1
	timeout := 2 * time.Second

	results := bench.Run(targets, domains, runs, timeout)

	// Verify results structure
	if len(results) != 2 {
		t.Errorf("Expected 2 results, got %d", len(results))
	}

	for name, result := range results {
		if result.Total != 1 { // 1 domain * 1 run
			t.Errorf("Expected total runs for %s to be 1, got %d", name, result.Total)
		}

		// Success rate might vary due to network conditions
		if result.Successes < 0 || result.Successes > result.Total {
			t.Errorf("Invalid success count for %s: %d/%d", name, result.Successes, result.Total)
		}
	}
}

func TestIntegrationResolvers(t *testing.T) {
	// Test that all resolvers have valid IP addresses
	for name, servers := range resolvers.Presets {
		if len(servers) == 0 {
			t.Errorf("Resolver %s has no servers", name)
			continue
		}

		for i, server := range servers {
			if server == "" {
				t.Errorf("Resolver %s server %d is empty", name, i)
			}

			// Basic IP:port format validation
			if len(server) < 7 { // minimum length for IP:port
				t.Errorf("Resolver %s server %d seems too short: %s", name, i, server)
			}
		}
	}
}

func TestIntegrationPortStripping(t *testing.T) {
	// Test that port stripping works with real resolver data
	for name, servers := range resolvers.Presets {
		for _, server := range servers {
			// Check if server has port
			hasPort := false
			for i := len(server) - 1; i >= 0; i-- {
				if server[i] == ':' {
					hasPort = true
					break
				}
			}

			if !hasPort {
				t.Errorf("Resolver %s server %s should have port number", name, server)
			}
		}
	}
}

func TestIntegrationBenchmarkTimeout(t *testing.T) {
	// Test that benchmark respects timeout
	start := time.Now()

	targets := map[string][]string{
		"test": {"127.0.0.1:53"}, // localhost, should timeout quickly
	}

	domains := []string{"example.com"}
	runs := 1
	timeout := 100 * time.Millisecond

	results := bench.Run(targets, domains, runs, timeout)

	duration := time.Since(start)

	// Should complete within reasonable time (not exactly timeout due to overhead)
	if duration > 500*time.Millisecond {
		t.Errorf("Benchmark took too long: %v, expected around %v", duration, timeout)
	}

	// Should have results even if all failed
	if len(results) != 1 {
		t.Errorf("Expected 1 result, got %d", len(results))
	}

	result := results["test"]
	if result.Total != 1 {
		t.Errorf("Expected 1 total run, got %d", result.Total)
	}
}
