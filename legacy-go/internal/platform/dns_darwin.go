//go:build darwin

package platform

// macOS implementation of DNS operations
// Uses networksetup, dscacheutil, and killall commands

import (
	"errors"
	"fmt"
	"strings"
	"time"

	"dns-helper/internal/util"
)

func listServices() ([]string, error) {
	out := util.Run(5*time.Second, "networksetup", "-listallnetworkservices")
	if out.Err != nil {
		return nil, out.Err
	}
	lines := strings.Split(out.Stdout, "\n")
	var svcs []string
	for _, l := range lines {
		l = strings.TrimSpace(l)
		if l == "" || strings.HasPrefix(l, "An asterisk") {
			continue
		}
		svcs = append(svcs, l)
	}
	if len(svcs) == 0 {
		return nil, errors.New("no network services found")
	}
	return svcs, nil
}

func stripPorts(servers []string) []string {
	out := make([]string, 0, len(servers))
	for _, s := range servers {
		if i := strings.Index(s, ":"); i > 0 {
			out = append(out, s[:i])
		} else {
			out = append(out, s)
		}
	}
	return out
}

func SwitchAll(servers []string, dryRun bool) error {
	svcs, err := listServices()
	if err != nil {
		return err
	}

	// Remove port numbers from DNS servers
	cleanServers := stripPorts(servers)

	fmt.Printf("Found %d network services: %v\n", len(svcs), svcs)
	fmt.Printf("Setting DNS servers: %v (cleaned: %v)\n", servers, cleanServers)

	for _, s := range svcs {
		if dryRun {
			fmt.Printf("[DRY-RUN] Would set DNS for: %s\n", s)
			continue
		}

		fmt.Printf("Setting DNS for: %s\n", s)
		args := append([]string{"-setdnsservers", s}, cleanServers...)
		out := util.Run(8*time.Second, "networksetup", args...)

		if out.Err != nil {
			fmt.Printf("Error setting DNS for %s: %v\n", s, out.Err)
			if out.Stderr != "" {
				fmt.Printf("Stderr: %s\n", out.Stderr)
			}
		} else {
			fmt.Printf("Successfully set DNS for: %s\n", s)
		}
	}

	if !dryRun {
		fmt.Println("Flushing DNS cache...")
		_ = util.Run(5*time.Second, "dscacheutil", "-flushcache").Err

		fmt.Println("Restarting mDNSResponder...")
		_ = util.Run(5*time.Second, "killall", "-HUP", "mDNSResponder").Err
	}

	return nil
}

func Status() (map[string][]string, error) {
	svcs, err := listServices()
	if err != nil {
		return nil, err
	}
	res := map[string][]string{}
	for _, s := range svcs {
		out := util.Run(5*time.Second, "networksetup", "-getdnsservers", s)
		if strings.Contains(out.Stdout, "There aren't any DNS Servers set") {
			res[s] = []string{}
			continue
		}
		if out.Err == nil && out.Stdout != "" {
			res[s] = strings.Split(out.Stdout, "\n")
		} else {
			res[s] = []string{}
		}
	}
	return res, nil
}

func ResetToDHCP(dryRun bool) error {
	svcs, err := listServices()
	if err != nil {
		return err
	}

	fmt.Printf("Found %d network services to reset\n", len(svcs))

	for _, s := range svcs {
		if dryRun {
			fmt.Printf("[DRY-RUN] Would reset DNS for: %s\n", s)
			continue
		}

		fmt.Printf("Resetting DNS for: %s\n", s)
		// macOS: use "empty" to reset to DHCP defaults (not empty string)
		out := util.Run(8*time.Second, "networksetup", "-setdnsservers", s, "empty")

		if out.Err != nil {
			fmt.Printf("Error resetting DNS for %s: %v\n", s, out.Err)
			if out.Stderr != "" {
				fmt.Printf("Stderr: %s\n", out.Stderr)
			}
		} else {
			fmt.Printf("Successfully reset DNS for: %s\n", s)
		}
	}

	if !dryRun {
		fmt.Println("Flushing DNS cache...")
		_ = util.Run(5*time.Second, "dscacheutil", "-flushcache").Err

		fmt.Println("Restarting mDNSResponder...")
		_ = util.Run(5*time.Second, "killall", "-HUP", "mDNSResponder").Err
	}

	return nil
}
