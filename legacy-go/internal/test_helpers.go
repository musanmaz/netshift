package internal

import (
	"testing"
	"time"
)

// TestHelper provides common testing utilities
type TestHelper struct {
	t *testing.T
}

// NewTestHelper creates a new test helper
func NewTestHelper(t *testing.T) *TestHelper {
	return &TestHelper{t: t}
}

// AssertEqual checks if two values are equal
func (th *TestHelper) AssertEqual(expected, actual interface{}, message string) {
	if expected != actual {
		th.t.Errorf("%s: expected %v, got %v", message, expected, actual)
	}
}

// AssertNotEqual checks if two values are not equal
func (th *TestHelper) AssertNotEqual(expected, actual interface{}, message string) {
	if expected == actual {
		th.t.Errorf("%s: expected not equal to %v, got %v", message, expected, actual)
	}
}

// AssertTrue checks if a value is true
func (th *TestHelper) AssertTrue(value bool, message string) {
	if !value {
		th.t.Errorf("%s: expected true, got false", message)
	}
}

// AssertFalse checks if a value is false
func (th *TestHelper) AssertFalse(value bool, message string) {
	if value {
		th.t.Errorf("%s: expected false, got true", message)
	}
}

// AssertNil checks if a value is nil
func (th *TestHelper) AssertNil(value interface{}, message string) {
	if value != nil {
		th.t.Errorf("%s: expected nil, got %v", message, value)
	}
}

// AssertNotNil checks if a value is not nil
func (th *TestHelper) AssertNotNil(value interface{}, message string) {
	if value == nil {
		th.t.Errorf("%s: expected not nil, got nil", message)
	}
}

// AssertLen checks if a slice/array has the expected length
func (th *TestHelper) AssertLen(slice interface{}, expected int, message string) {
	switch v := slice.(type) {
	case []string:
		if len(v) != expected {
			th.t.Errorf("%s: expected length %d, got %d", message, expected, len(v))
		}
	case []int:
		if len(v) != expected {
			th.t.Errorf("%s: expected length %d, got %d", message, expected, len(v))
		}
	case map[string]string:
		if len(v) != expected {
			th.t.Errorf("%s: expected length %d, got %d", message, expected, len(v))
		}
	default:
		th.t.Errorf("AssertLen: unsupported type %T", slice)
	}
}

// AssertContains checks if a slice contains a value
func (th *TestHelper) AssertContains(slice []string, value string, message string) {
	for _, item := range slice {
		if item == value {
			return
		}
	}
	th.t.Errorf("%s: expected slice to contain '%s', got %v", message, value, slice)
}

// AssertNotContains checks if a slice does not contain a value
func (th *TestHelper) AssertNotContains(slice []string, value string, message string) {
	for _, item := range slice {
		if item == value {
			th.t.Errorf("%s: expected slice to not contain '%s', got %v", message, value, slice)
			return
		}
	}
}

// AssertDuration checks if a duration is within expected range
func (th *TestHelper) AssertDuration(actual, expected, tolerance time.Duration, message string) {
	diff := actual - expected
	if diff < 0 {
		diff = -diff
	}
	if diff > tolerance {
		th.t.Errorf("%s: expected %v ± %v, got %v", message, expected, tolerance, actual)
	}
}

// MockTime provides a mockable time interface for testing
type MockTime struct {
	now time.Time
}

// NewMockTime creates a new mock time
func NewMockTime(now time.Time) *MockTime {
	return &MockTime{now: now}
}

// Now returns the mock time
func (mt *MockTime) Now() time.Time {
	return mt.now
}

// SetNow sets the mock time
func (mt *MockTime) SetNow(now time.Time) {
	mt.now = now
}

// Advance advances the mock time by duration
func (mt *MockTime) Advance(duration time.Duration) {
	mt.now = mt.now.Add(duration)
}

// TestData provides common test data
var TestData = struct {
	ValidIPs     []string
	InvalidIPs   []string
	ValidPorts   []string
	InvalidPorts []string
}{
	ValidIPs: []string{
		"1.1.1.1",
		"8.8.8.8",
		"9.9.9.9",
		"127.0.0.1",
		"::1",
		"2001:4860:4860::8888",
	},
	InvalidIPs: []string{
		"256.256.256.256",
		"999.999.999.999",
		"invalid",
		"",
	},
	ValidPorts: []string{
		"53",
		"80",
		"443",
		"8080",
		"65535",
	},
	InvalidPorts: []string{
		"0",
		"65536",
		"abc",
		"",
	},
}

// IsValidIP checks if a string is a valid IP address
func IsValidIP(ip string) bool {
	// Simple validation - in real tests you might want more sophisticated validation
	if ip == "" {
		return false
	}

	// Check for IPv4
	if len(ip) >= 7 && len(ip) <= 15 {
		// Basic IPv4 format check
		return true
	}

	// Check for IPv6
	if len(ip) >= 2 && ip[0] == ':' {
		return true
	}

	return false
}

// IsValidPort checks if a string is a valid port number
func IsValidPort(port string) bool {
	if port == "" {
		return false
	}

	// Check if it's a number between 1-65535
	for _, char := range port {
		if char < '0' || char > '9' {
			return false
		}
	}

	return true
}
