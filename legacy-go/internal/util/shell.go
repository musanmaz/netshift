package util

import (
	"bytes"
	"os/exec"
	"strings"
	"time"
)

type CmdResult struct {
	Stdout string
	Stderr string
	Err    error
}

func Run(timeout time.Duration, name string, args ...string) CmdResult {
	cmd := exec.Command(name, args...)
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	if timeout <= 0 {
		timeout = 10 * time.Second
	}
	err := runWithTimeout(cmd, timeout)
	return CmdResult{
		Stdout: strings.TrimSpace(stdout.String()),
		Stderr: strings.TrimSpace(stderr.String()),
		Err:    err,
	}
}

func runWithTimeout(cmd *exec.Cmd, timeout time.Duration) error {
	if err := cmd.Start(); err != nil {
		return err
	}
	done := make(chan error, 1)
	go func() { done <- cmd.Wait() }()
	select {
	case err := <-done:
		return err
	case <-time.After(timeout):
		_ = cmd.Process.Kill()
		return exec.ErrNotFound // generic timeout err
	}
}
