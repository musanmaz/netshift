package bench

import (
	"context"
	"net"
	"sort"
	"time"
)

// Result contains statistics for a single profile
type Result struct {
	Latencies []time.Duration
	Successes int
	Total     int
}

func (r Result) AvgMS() float64 {
	if len(r.Latencies) == 0 {
		return 0
	}
	var sum time.Duration
	for _, d := range r.Latencies {
		sum += d
	}
	return float64(sum.Milliseconds()) / float64(len(r.Latencies))
}
func (r Result) P50MS() float64 { return percentile(r.Latencies, 0.50) }
func (r Result) P90MS() float64 { return percentile(r.Latencies, 0.90) }

func percentile(durs []time.Duration, p float64) float64 {
	if len(durs) == 0 {
		return 0
	}
	cp := append([]time.Duration(nil), durs...)
	sort.Slice(cp, func(i, j int) bool { return cp[i] < cp[j] })
	idx := int(float64(len(cp)-1) * p)
	return float64(cp[idx].Milliseconds())
}

// Run: profileName -> IP:port list
func Run(targets map[string][]string, domains []string, runs int, timeout time.Duration) map[string]Result {
	out := make(map[string]Result)
	for name, servers := range targets {
		res := Result{}
		for _, domain := range domains {
			for i := 0; i < runs; i++ {
				start := time.Now()
				ok := resolveOnce(servers, domain, timeout)
				res.Total++
				if ok {
					res.Successes++
					res.Latencies = append(res.Latencies, time.Since(start))
				}
			}
		}
		out[name] = res
	}
	return out
}

func resolveOnce(servers []string, domain string, timeout time.Duration) bool {
	// custom resolver: UDP 53
	dialer := func(ctx context.Context, network, address string) (net.Conn, error) {
		// try servers in order
		var lastErr error
		for _, s := range servers {
			d := net.Dialer{}
			c, err := d.DialContext(ctx, "udp", s)
			if err == nil {
				return c, nil
			}
			lastErr = err
		}
		return nil, lastErr
	}
	r := &net.Resolver{
		PreferGo: true,
		Dial:     dialer,
	}
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	_, err := r.LookupHost(ctx, domain)
	return err == nil
}
