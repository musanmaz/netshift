//go:build test
// +build test

package main

import (
	"os"
	"testing"
)

// TestMain runs before all tests
func TestMain(m *testing.M) {
	// Setup test environment
	setupTestEnvironment()

	// Run tests
	code := m.Run()

	// Cleanup test environment
	cleanupTestEnvironment()

	// Exit with test result code
	os.Exit(code)
}

// setupTestEnvironment prepares the test environment
func setupTestEnvironment() {
	// Set test environment variables
	os.Setenv("DNS_HELPER_TEST", "true")
	os.Setenv("DNS_HELPER_DEBUG", "true")

	// Create test directories if needed
	// os.MkdirAll("testdata", 0755)
}

// cleanupTestEnvironment cleans up after tests
func cleanupTestEnvironment() {
	// Remove test files/directories
	// os.RemoveAll("testdata")

	// Unset test environment variables
	os.Unsetenv("DNS_HELPER_TEST")
	os.Unsetenv("DNS_HELPER_DEBUG")
}

// TestConfig provides test configuration
type TestConfig struct {
	SkipNetworkTests bool
	SkipSlowTests    bool
	VerboseOutput    bool
	TestTimeout      string
}

// GetTestConfig returns test configuration from environment
func GetTestConfig() TestConfig {
	return TestConfig{
		SkipNetworkTests: os.Getenv("DNS_HELPER_SKIP_NETWORK") == "true",
		SkipSlowTests:    os.Getenv("DNS_HELPER_SKIP_SLOW") == "true",
		VerboseOutput:    os.Getenv("DNS_HELPER_VERBOSE") == "true",
		TestTimeout:      getEnvOrDefault("DNS_HELPER_TIMEOUT", "30s"),
	}
}

// getEnvOrDefault gets environment variable or returns default
func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// SkipIfNetworkTestsSkipped skips test if network tests are disabled
func SkipIfNetworkTestsSkipped(t *testing.T) {
	config := GetTestConfig()
	if config.SkipNetworkTests {
		t.Skip("Skipping network test (DNS_HELPER_SKIP_NETWORK=true)")
	}
}

// SkipIfSlowTestsSkipped skips test if slow tests are disabled
func SkipIfSlowTestsSkipped(t *testing.T) {
	config := GetTestConfig()
	if config.SkipSlowTests {
		t.Skip("Skipping slow test (DNS_HELPER_SKIP_SLOW=true)")
	}
}

// TestDataDir returns the test data directory
func TestDataDir() string {
	return "testdata"
}

// CreateTestFile creates a test file with content
func CreateTestFile(t *testing.T, filename, content string) string {
	filepath := TestDataDir() + "/" + filename
	err := os.WriteFile(filepath, []byte(content), 0644)
	if err != nil {
		t.Fatalf("Failed to create test file %s: %v", filepath, err)
	}
	return filepath
}

// RemoveTestFile removes a test file
func RemoveTestFile(t *testing.T, filepath string) {
	err := os.Remove(filepath)
	if err != nil {
		t.Logf("Failed to remove test file %s: %v", filepath, err)
	}
}
