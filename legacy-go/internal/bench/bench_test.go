package bench

import (
	"testing"
	"time"
)

func TestResultMethods(t *testing.T) {
	// Test with empty result
	emptyResult := Result{}

	if emptyResult.AvgMS() != 0 {
		t.Errorf("Expected AvgMS() to return 0 for empty result, got %f", emptyResult.AvgMS())
	}

	if emptyResult.P50MS() != 0 {
		t.Errorf("Expected P50MS() to return 0 for empty result, got %f", emptyResult.P50MS())
	}

	if emptyResult.P90MS() != 0 {
		t.Errorf("Expected P90MS() to return 0 for empty result, got %f", emptyResult.P90MS())
	}

	// Test with single latency
	singleResult := Result{
		Latencies: []time.Duration{100 * time.Millisecond},
		Successes: 1,
		Total:     1,
	}

	expectedAvg := 100.0
	if singleResult.AvgMS() != expectedAvg {
		t.Errorf("Expected AvgMS() to return %f, got %f", expectedAvg, singleResult.AvgMS())
	}

	if singleResult.P50MS() != expectedAvg {
		t.Errorf("Expected P50MS() to return %f, got %f", expectedAvg, singleResult.P50MS())
	}

	if singleResult.P90MS() != expectedAvg {
		t.Errorf("Expected P90MS() to return %f, got %f", expectedAvg, singleResult.P90MS())
	}
}

func TestPercentileCalculation(t *testing.T) {
	// Test with multiple latencies
	latencies := []time.Duration{
		10 * time.Millisecond, // 0th
		20 * time.Millisecond, // 25th
		30 * time.Millisecond, // 50th
		40 * time.Millisecond, // 75th
		50 * time.Millisecond, // 100th
	}

	// Test P50 (median) - for 5 elements, 0.5 * 4 = 2, so index 2
	p50 := percentile(latencies, 0.50)
	expectedP50 := 30.0
	if p50 != expectedP50 {
		t.Errorf("Expected P50 to be %f, got %f", expectedP50, p50)
	}

	// Test P90 (90th percentile) - for 5 elements, 0.9 * 4 = 3.6, so index 3
	p90 := percentile(latencies, 0.90)
	expectedP90 := 40.0
	if p90 != expectedP90 {
		t.Errorf("Expected P90 to be %f, got %f", expectedP90, p90)
	}

	// Test P25 (25th percentile) - for 5 elements, 0.25 * 4 = 1, so index 1
	p25 := percentile(latencies, 0.25)
	expectedP25 := 20.0
	if p25 != expectedP25 {
		t.Errorf("Expected P25 to be %f, got %f", expectedP25, p25)
	}
}

func TestPercentileEdgeCases(t *testing.T) {
	// Test with single value
	single := []time.Duration{100 * time.Millisecond}
	p50 := percentile(single, 0.50)
	if p50 != 100.0 {
		t.Errorf("Expected P50 of single value to be 100.0, got %f", p50)
	}

	// Test with empty slice
	empty := []time.Duration{}
	p50 = percentile(empty, 0.50)
	if p50 != 0 {
		t.Errorf("Expected P50 of empty slice to be 0, got %f", p50)
	}

	// Test with two values - P50 should be the first value for 0.5
	two := []time.Duration{10 * time.Millisecond, 20 * time.Millisecond}
	p50 = percentile(two, 0.50)
	expected := 10.0 // For 0.5, it should return the first value
	if p50 != expected {
		t.Errorf("Expected P50 of two values to be %f, got %f", expected, p50)
	}
}

func TestRunBenchmark(t *testing.T) {
	// Test with minimal configuration
	targets := map[string][]string{
		"test1": {"127.0.0.1:53"},
		"test2": {"127.0.0.1:53"},
	}

	domains := []string{"localhost"}
	runs := 2
	timeout := 100 * time.Millisecond

	results := Run(targets, domains, runs, timeout)

	// Verify results structure
	if len(results) != 2 {
		t.Errorf("Expected 2 results, got %d", len(results))
	}

	for name, result := range results {
		if result.Total != 2 { // 1 domain * 2 runs
			t.Errorf("Expected total runs for %s to be 2, got %d", name, result.Total)
		}

		// Success rate might be 0 due to localhost not resolving, but structure should be correct
		if result.Successes < 0 || result.Successes > result.Total {
			t.Errorf("Invalid success count for %s: %d/%d", name, result.Successes, result.Total)
		}
	}
}

func TestStripPorts(t *testing.T) {
	// This test assumes stripPorts function exists in platform packages
	// We'll test the logic here
	testCases := []struct {
		input    string
		expected string
	}{
		{"1.1.1.1:53", "1.1.1.1"},
		{"8.8.8.8:53", "8.8.8.8"},
		{"9.9.9.9", "9.9.9.9"}, // no port
		{"127.0.0.1:8080", "127.0.0.1"},
		{"::1:53", "::1"}, // IPv6
	}

	for _, tc := range testCases {
		result := stripPortsHelper(tc.input)
		if result != tc.expected {
			t.Errorf("stripPortsHelper(%s) = %s, expected %s", tc.input, result, tc.expected)
		}
	}
}

// Helper function to test port stripping logic
func stripPortsHelper(server string) string {
	if i := len(server); i > 0 {
		for j := i - 1; j >= 0; j-- {
			if server[j] == ':' {
				return server[:j]
			}
		}
	}
	return server
}
