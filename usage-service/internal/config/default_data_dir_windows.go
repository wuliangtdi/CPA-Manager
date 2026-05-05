//go:build windows

package config

import (
	"os"
	"path/filepath"
)

func defaultDataDir() string {
	exePath, err := os.Executable()
	if err != nil {
		return "data"
	}
	return filepath.Join(filepath.Dir(exePath), "data")
}
