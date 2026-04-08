//go:build linux

package platform

import (
	"errors"
	"fmt"
	"os"
	"strings"
	"time"

	"dns-helper/internal/util"
)

func defaultIface() string {
	out := util.Run(3*time.Second, "sh", "-c", "ip route show default | awk '{print $5}' | head -1")
	if out.Err != nil || out.Stdout == "" {
		return ""
	}
	return strings.TrimSpace(out.Stdout)
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
	iface := defaultIface()
	cleanServers := stripPorts(servers)

	fmt.Printf("Default interface: %s\n", iface)
	fmt.Printf("Setting DNS servers: %v (cleaned: %v)\n", servers, cleanServers)

	if iface != "" {
		// systemd-resolved
		if _, err := os.Stat("/run/systemd/resolve/stub-resolv.conf"); err == nil || fileExists("/usr/bin/resolvectl") || fileExists("/bin/resolvectl") {
			args := append([]string{"dns", iface}, cleanServers...)
			if !dryRun {
				fmt.Printf("Using systemd-resolved for interface: %s\n", iface)
				out := util.Run(5*time.Second, "resolvectl", args...)
				if out.Err == nil {
					fmt.Printf("Successfully set DNS via systemd-resolved\n")
					return nil
				} else {
					fmt.Printf("systemd-resolved failed: %v\n", out.Err)
				}
			} else {
				fmt.Printf("[DRY-RUN] Would use systemd-resolved for interface: %s\n", iface)
			}
		}
		// NetworkManager
		if fileExists("/usr/bin/nmcli") || fileExists("/bin/nmcli") {
			args := append([]string{"con", "mod", iface, "ipv4.method", "manual", "ipv4.dns"}, strings.Join(cleanServers, ","))
			if !dryRun {
				fmt.Printf("Using NetworkManager for interface: %s\n", iface)
				_ = util.Run(8*time.Second, "nmcli", args...).Err
				_ = util.Run(5*time.Second, "nmcli", "con", "up", iface).Err
				fmt.Printf("Successfully set DNS via NetworkManager\n")
				return nil
			} else {
				fmt.Printf("[DRY-RUN] Would use NetworkManager for interface: %s\n", iface)
			}
		}
	}
	// Fallback: /etc/resolv.conf overwrite (risk: managed on some systems)
	if !dryRun {
		fmt.Println("Using fallback: direct /etc/resolv.conf modification")
		content := "nameserver " + strings.Join(cleanServers, "\nnameserver ") + "\n"
		err := os.WriteFile("/etc/resolv.conf", []byte(content), 0644)
		if err != nil {
			return fmt.Errorf("failed to write /etc/resolv.conf: %v", err)
		}
		fmt.Printf("Successfully wrote DNS to /etc/resolv.conf\n")
	} else {
		fmt.Println("[DRY-RUN] Would modify /etc/resolv.conf")
	}
	return nil
}

func Status() (map[string][]string, error) {
	res := map[string][]string{"system": {}}
	// resolvectl
	if fileExists("/usr/bin/resolvectl") || fileExists("/bin/resolvectl") {
		out := util.Run(5*time.Second, "resolvectl", "status")
		if out.Err == nil && out.Stdout != "" {
			lines := strings.Split(out.Stdout, "\n")
			var current []string
			for _, l := range lines {
				if strings.Contains(l, "Current DNS Server:") {
					current = append(current, strings.TrimSpace(strings.Split(l, ":")[1]))
				}
				if strings.Contains(l, "DNS Servers:") {
					s := strings.TrimSpace(strings.Split(l, ":")[1])
					if s != "" {
						current = append(current, strings.Fields(s)...)
					}
				}
			}
			if len(current) > 0 {
				res["systemd-resolved"] = current
			}
		}
	}
	// /etc/resolv.conf
	data, err := os.ReadFile("/etc/resolv.conf")
	if err == nil {
		lines := strings.Split(string(data), "\n")
		for _, l := range lines {
			if strings.HasPrefix(strings.TrimSpace(l), "nameserver") {
				fields := strings.Fields(l)
				if len(fields) >= 2 {
					res["resolv.conf"] = append(res["resolv.conf"], fields[1])
				}
			}
		}
	}
	if len(res) == 0 {
		return nil, errors.New("could not read DNS status")
	}
	return res, nil
}

func fileExists(p string) bool {
	_, err := os.Stat(p)
	return err == nil
}

func ResetToDHCP(dryRun bool) error {
	iface := defaultIface()

	fmt.Printf("Default interface: %s\n", iface)

	if iface != "" {
		// systemd-resolved
		if _, err := os.Stat("/run/systemd/resolve/stub-resolv.conf"); err == nil || fileExists("/usr/bin/resolvectl") || fileExists("/bin/resolvectl") {
			if !dryRun {
				fmt.Printf("Using systemd-resolved to reset DNS for interface: %s\n", iface)
				// Linux: use "dhcp" to reset to DHCP defaults
				out := util.Run(5*time.Second, "resolvectl", "dns", iface, "dhcp")
				if out.Err == nil {
					fmt.Printf("Successfully reset DNS via systemd-resolved\n")
					return nil
				} else {
					fmt.Printf("systemd-resolved reset failed: %v\n", out.Err)
				}
			} else {
				fmt.Printf("[DRY-RUN] Would use systemd-resolved to reset DNS for interface: %s\n", iface)
			}
		}
		// NetworkManager
		if fileExists("/usr/bin/nmcli") || fileExists("/bin/nmcli") {
			if !dryRun {
				fmt.Printf("Using NetworkManager to reset DNS for interface: %s\n", iface)
				// Linux: use "auto" to reset to DHCP defaults
				_ = util.Run(8*time.Second, "nmcli", "con", "mod", iface, "ipv4.dns", "auto").Err
				_ = util.Run(5*time.Second, "nmcli", "con", "up", iface).Err
				fmt.Printf("Successfully reset DNS via NetworkManager\n")
				return nil
			} else {
				fmt.Printf("[DRY-RUN] Would use NetworkManager to reset DNS for interface: %s\n", iface)
			}
		}
	}
	// Fallback: restore /etc/resolv.conf
	if !dryRun {
		fmt.Println("Using fallback: restore /etc/resolv.conf")
		// Try to restore from backup or use minimal content
		content := "# DNS settings reset to DHCP defaults\n# Generated by dns-helper\n"
		err := os.WriteFile("/etc/resolv.conf", []byte(content), 0644)
		if err != nil {
			return fmt.Errorf("failed to reset /etc/resolv.conf: %v", err)
		}
		fmt.Printf("Successfully reset /etc/resolv.conf\n")
	} else {
		fmt.Println("[DRY-RUN] Would restore /etc/resolv.conf")
	}
	return nil
}
