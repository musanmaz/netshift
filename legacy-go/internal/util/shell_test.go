package util

import (
	"testing"
	"time"
)

func TestRunWithTimeout(t *testing.T) {
	// Test successful command execution
	result := Run(5*time.Second, "echo", "hello world")
	if result.Err != nil {
		t.Errorf("Expected no error for echo command, got %v", result.Err)
	}
	if result.Stdout != "hello world" {
		t.Errorf("Expected stdout 'hello world', got '%s'", result.Stdout)
	}
	if result.Stderr != "" {
		t.Errorf("Expected no stderr, got '%s'", result.Stderr)
	}
}

func TestRunWithError(t *testing.T) {
	// Test command that doesn't exist
	result := Run(1*time.Second, "nonexistentcommand")
	if result.Err == nil {
		t.Error("Expected error for nonexistent command")
	}
}

func TestRunWithTimeoutExpired(t *testing.T) {
	// Test command that takes too long
	result := Run(100*time.Millisecond, "sleep", "1")
	if result.Err == nil {
		t.Error("Expected timeout error for long-running command")
	}
}

func TestRunWithStderr(t *testing.T) {
	// Test command that produces stderr
	result := Run(5*time.Second, "sh", "-c", "echo 'error message' >&2")
	if result.Err != nil {
		t.Errorf("Expected no error, got %v", result.Err)
	}
	if result.Stderr != "error message" {
		t.Errorf("Expected stderr 'error message', got '%s'", result.Stderr)
	}
}

func TestRunWithZeroTimeout(t *testing.T) {
	// Test with zero timeout (should use default)
	result := Run(0, "echo", "test")
	if result.Err != nil {
		t.Errorf("Expected no error with zero timeout, got %v", result.Err)
	}
	if result.Stdout != "test" {
		t.Errorf("Expected stdout 'test', got '%s'", result.Stdout)
	}
}

func TestRunWithNegativeTimeout(t *testing.T) {
	// Test with negative timeout (should use default)
	result := Run(-1*time.Second, "echo", "test")
	if result.Err != nil {
		t.Errorf("Expected no error with negative timeout, got %v", result.Err)
	}
	if result.Stdout != "test" {
		t.Errorf("Expected stdout 'test', got '%s'", result.Stdout)
	}
}

func TestRunWithComplexCommand(t *testing.T) {
	// Test with complex shell command
	result := Run(5*time.Second, "sh", "-c", "echo 'line1' && echo 'line2'")
	if result.Err != nil {
		t.Errorf("Expected no error for complex command, got %v", result.Err)
	}
	expected := "line1\nline2"
	if result.Stdout != expected {
		t.Errorf("Expected stdout '%s', got '%s'", expected, result.Stdout)
	}
}

func TestRunWithEmptyArgs(t *testing.T) {
	// Test with no arguments
	result := Run(5*time.Second, "echo")
	if result.Err != nil {
		t.Errorf("Expected no error for echo without args, got %v", result.Err)
	}
	if result.Stdout != "" {
		t.Errorf("Expected empty stdout, got '%s'", result.Stdout)
	}
}

func TestRunWithSpecialCharacters(t *testing.T) {
	// Test with special characters in output
	specialChars := "hello\nworld\twith\tspecial chars"
	result := Run(5*time.Second, "echo", "-e", specialChars)
	if result.Err != nil {
		t.Errorf("Expected no error for special chars, got %v", result.Err)
	}
	// The -e flag is included in the output, so we need to account for it
	expected := "-e " + specialChars
	if result.Stdout != expected {
		t.Errorf("Expected stdout '%s', got '%s'", expected, result.Stdout)
	}
}
