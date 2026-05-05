//go:build !windows

package config

func defaultDataDir() string {
	return "/data"
}
