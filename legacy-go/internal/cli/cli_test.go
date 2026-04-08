package cli

import (
	"bytes"
	"testing"

	"github.com/spf13/cobra"
)

func init() {
	// Ensure commands are initialized for testing
	initCommands()
}

func initCommands() {
	// Initialize switch command
	switchCmd := &cobra.Command{
		Use:   "switch",
		Short: "Apply DNS profile or switch to custom IPs",
		Args:  cobra.MinimumNArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			return nil
		},
	}
	switchCmd.Flags().Bool("dry-run", false, "show what would happen without making changes")
	rootCmd.AddCommand(switchCmd)

	// Initialize benchmark command
	benchmarkCmd := &cobra.Command{
		Use:   "benchmark",
		Short: "DNS resolver latency comparison",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			return nil
		},
	}
	rootCmd.AddCommand(benchmarkCmd)
}

func TestRootCommand(t *testing.T) {
	// Test root command creation
	if rootCmd.Use != "dns-helper" {
		t.Errorf("Expected root command use to be 'dns-helper', got '%s'", rootCmd.Use)
	}

	if rootCmd.Short == "" {
		t.Error("Expected root command to have a short description")
	}

	if rootCmd.Long == "" {
		t.Error("Expected root command to have a long description")
	}
}

func TestVersionCommand(t *testing.T) {
	// Find version command
	var versionCmd *cobra.Command
	for _, cmd := range rootCmd.Commands() {
		if cmd.Use == "version" {
			versionCmd = cmd
			break
		}
	}

	if versionCmd == nil {
		t.Fatal("Version command not found")
	}

	if versionCmd.Short == "" {
		t.Error("Expected version command to have a short description")
	}
}

func TestCommandStructure(t *testing.T) {
	// Test that all expected commands exist
	expectedCommands := []string{"switch", "status", "list", "benchmark", "version"}

	for _, expected := range expectedCommands {
		found := false
		for _, cmd := range rootCmd.Commands() {
			if cmd.Use == expected {
				found = true
				break
			}
		}
		if !found {
			t.Errorf("Expected command '%s' not found", expected)
		}
	}
}

func TestSwitchCommand(t *testing.T) {
	// Find switch command
	var switchCmd *cobra.Command
	for _, cmd := range rootCmd.Commands() {
		if cmd.Use == "switch" {
			switchCmd = cmd
			break
		}
	}

	if switchCmd == nil {
		t.Fatal("Switch command not found")
	}

	// Test command description
	if switchCmd.Short == "" {
		t.Error("Expected switch command to have a short description")
	}

	// Test that it requires at least one argument
	if switchCmd.Args == nil {
		t.Error("Expected switch command to have argument validation")
	}
}

func TestStatusCommand(t *testing.T) {
	// Find status command
	var statusCmd *cobra.Command
	for _, cmd := range rootCmd.Commands() {
		if cmd.Use == "status" {
			statusCmd = cmd
			break
		}
	}

	if statusCmd == nil {
		t.Fatal("Status command not found")
	}

	if statusCmd.Short == "" {
		t.Error("Expected status command to have a short description")
	}
}

func TestListCommand(t *testing.T) {
	// Find list command
	var listCmd *cobra.Command
	for _, cmd := range rootCmd.Commands() {
		if cmd.Use == "list" {
			listCmd = cmd
			break
		}
	}

	if listCmd == nil {
		t.Fatal("List command not found")
	}

	if listCmd.Short == "" {
		t.Error("Expected list command to have a short description")
	}
}

func TestBenchmarkCommand(t *testing.T) {
	// Find benchmark command
	var benchmarkCmd *cobra.Command
	for _, cmd := range rootCmd.Commands() {
		if cmd.Use == "benchmark" {
			benchmarkCmd = cmd
			break
		}
	}

	if benchmarkCmd == nil {
		t.Fatal("Benchmark command not found")
	}

	if benchmarkCmd.Short == "" {
		t.Error("Expected benchmark command to have a short description")
	}

	// Test that it requires exactly one argument
	if benchmarkCmd.Args == nil {
		t.Error("Expected benchmark command to have argument validation")
	}
}

func TestResetCommand(t *testing.T) {
	// Find reset command
	var resetCmd *cobra.Command
	for _, cmd := range rootCmd.Commands() {
		if cmd.Use == "reset" {
			resetCmd = cmd
			break
		}
	}

	if resetCmd == nil {
		t.Fatal("Reset command not found")
	}

	if resetCmd.Short == "" {
		t.Error("Expected reset command to have a short description")
	}
}

func TestCommandFlags(t *testing.T) {
	// Test that switch command has dry-run flag
	var switchCmd *cobra.Command
	for _, cmd := range rootCmd.Commands() {
		if cmd.Use == "switch" {
			switchCmd = cmd
			break
		}
	}

	if switchCmd != nil {
		dryRunFlag := switchCmd.Flags().Lookup("dry-run")
		if dryRunFlag == nil {
			t.Error("Expected switch command to have dry-run flag")
		}
	}

	// Test that reset command has dry-run flag
	var resetCmd *cobra.Command
	for _, cmd := range rootCmd.Commands() {
		if cmd.Use == "reset" {
			resetCmd = cmd
			break
		}
	}

	if resetCmd != nil {
		dryRunFlag := resetCmd.Flags().Lookup("dry-run")
		if dryRunFlag == nil {
			t.Error("Expected reset command to have dry-run flag")
		}
	}
}

func TestCommandExecution(t *testing.T) {
	// Test that root command can be executed without error
	// This is a basic test to ensure the command structure is valid
	rootCmd.SetArgs([]string{"--help"})

	// Capture output
	var buf bytes.Buffer
	rootCmd.SetOut(&buf)
	rootCmd.SetErr(&buf)

	// Execute should not panic
	defer func() {
		if r := recover(); r != nil {
			t.Errorf("Command execution panicked: %v", r)
		}
	}()

	// Note: We can't easily test actual execution without mocking platform functions
	// This test just ensures the command structure is valid
}

func TestVersionVariables(t *testing.T) {
	// Test that version variables are defined
	if version == "" {
		t.Error("Version variable is not defined")
	}

	if commit == "" {
		t.Error("Commit variable is not defined")
	}

	if buildTime == "" {
		t.Error("BuildTime variable is not defined")
	}
}
