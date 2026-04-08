package resolvers

import (
	"testing"
)

func TestPresets(t *testing.T) {
	// Test that all expected profiles exist
	expectedProfiles := []string{"cloudflare", "google", "quad9", "opendns"}

	for _, profile := range expectedProfiles {
		if _, exists := Presets[profile]; !exists {
			t.Errorf("Expected profile '%s' not found in Presets", profile)
		}
	}

	// Test that no unexpected profiles exist
	if len(Presets) != len(expectedProfiles) {
		t.Errorf("Expected %d profiles, got %d", len(expectedProfiles), len(Presets))
	}
}

func TestPresetContent(t *testing.T) {
	tests := []struct {
		name     string
		expected []string
	}{
		{
			name:     "cloudflare",
			expected: []string{"1.1.1.1:53", "1.0.0.1:53"},
		},
		{
			name:     "google",
			expected: []string{"8.8.8.8:53", "8.8.4.4:53"},
		},
		{
			name:     "quad9",
			expected: []string{"9.9.9.9:53", "149.112.112.112:53"},
		},
		{
			name:     "opendns",
			expected: []string{"208.67.222.222:53", "208.67.220.220:53"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			servers, exists := Presets[tt.name]
			if !exists {
				t.Fatalf("Profile '%s' not found", tt.name)
			}

			if len(servers) != len(tt.expected) {
				t.Errorf("Expected %d servers, got %d", len(tt.expected), len(servers))
			}

			for i, expected := range tt.expected {
				if i >= len(servers) {
					t.Errorf("Expected server %d: %s, but not enough servers", i, expected)
					continue
				}
				if servers[i] != expected {
					t.Errorf("Expected server %d: %s, got %s", i, expected, servers[i])
				}
			}
		})
	}
}

func TestPresetOrder(t *testing.T) {
	// Test that primary DNS servers are first in the list
	cloudflare := Presets["cloudflare"]
	if len(cloudflare) < 1 || cloudflare[0] != "1.1.1.1:53" {
		t.Errorf("Expected primary Cloudflare DNS to be first, got %v", cloudflare)
	}

	google := Presets["google"]
	if len(google) < 1 || google[0] != "8.8.8.8:53" {
		t.Errorf("Expected primary Google DNS to be first, got %v", google)
	}
}
