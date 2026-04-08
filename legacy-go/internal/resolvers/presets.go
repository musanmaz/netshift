package resolvers

// Presets: common DNS profiles. Order matters.
var Presets = map[string][]string{
	"cloudflare": {"1.1.1.1:53", "1.0.0.1:53"},
	"google":     {"8.8.8.8:53", "8.8.4.4:53"},
	"quad9":      {"9.9.9.9:53", "149.112.112.112:53"},
	"opendns":    {"208.67.222.222:53", "208.67.220.220:53"},
}
