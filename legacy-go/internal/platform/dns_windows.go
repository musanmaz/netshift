//go:build windows

package platform

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"dns-helper/internal/util"
)

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
	cleanServers := stripPorts(servers)

	fmt.Printf("Setting DNS servers: %v (cleaned: %v)\n", servers, cleanServers)

	// PowerShell: apply to all UP adapters
	psServers := "'" + strings.Join(cleanServers, "','") + "'"
	script := fmt.Sprintf(`Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses @(%s) }`, psServers)

	if !dryRun {
		fmt.Println("Using PowerShell to set DNS for all active adapters")
		out := util.Run(15*time.Second, "powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", script)
		if out.Err != nil {
			return fmt.Errorf("PowerShell command failed: %v", out.Err)
		}
		fmt.Printf("Successfully set DNS via PowerShell\n")
	} else {
		fmt.Println("[DRY-RUN] Would use PowerShell to set DNS for all active adapters")
	}

	return nil
}

func Status() (map[string][]string, error) {
	res := map[string][]string{}
	script := `Get-DnsClientServerAddress | Where-Object {$_.ServerAddresses} | Select-Object InterfaceAlias,ServerAddresses | ConvertTo-Json`
	out := util.Run(10*time.Second, "powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", script)
	if out.Err != nil {
		return res, out.Err
	}
	// minimal parse (simple/robust)
	type item struct {
		InterfaceAlias  string
		ServerAddresses []string
	}
	var items []item
	_ = jsonUnmarshal(out.Stdout, &items)
	for _, it := range items {
		res[it.InterfaceAlias] = it.ServerAddresses
	}
	return res, nil
}

// minimal JSON helper (for PowerShell output)
func jsonUnmarshal(s string, v interface{}) error {
	dec := json.NewDecoder(strings.NewReader(s))
	return dec.Decode(v)
}

func ResetToDHCP(dryRun bool) error {
	fmt.Println("Resetting DNS to DHCP defaults")

	// PowerShell: reset all adapters to DHCP DNS
	// Windows: use -ResetServerAddresses to restore DHCP DNS
	script := `Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { 
		Write-Host "Resetting DNS for adapter: $($_.Name)"
		Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses
	}`

	if !dryRun {
		fmt.Println("Using PowerShell to reset DNS for all active adapters")
		out := util.Run(15*time.Second, "powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", script)
		if out.Err != nil {
			return fmt.Errorf("PowerShell reset command failed: %v", out.Err)
		}
		fmt.Printf("Successfully reset DNS via PowerShell\n")
	} else {
		fmt.Println("[DRY-RUN] Would use PowerShell to reset DNS for all active adapters")
	}

	return nil
}
