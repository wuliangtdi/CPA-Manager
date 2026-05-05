//go:build windows

package main

import (
	"context"
	"io"
	"log"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"

	"golang.org/x/sys/windows/svc"
)

const windowsServiceName = "CPAManagerUsageService"

type windowsService struct{}

func runPlatform() error {
	isService, err := svc.IsWindowsService()
	if err != nil {
		log.Printf("detect windows service mode: %v", err)
	}
	if isService {
		logFile, err := configureWindowsServiceLogging()
		if err != nil {
			log.Printf("configure service logging: %v", err)
		} else {
			defer logFile.Close()
		}
		return svc.Run(serviceName(), windowsService{})
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	return run(ctx)
}

func serviceName() string {
	for index, arg := range os.Args {
		switch arg {
		case "-service-name", "--service-name":
			if index+1 < len(os.Args) && os.Args[index+1] != "" {
				return os.Args[index+1]
			}
		}
	}
	if name := os.Getenv("CPA_MANAGER_SERVICE_NAME"); name != "" {
		return name
	}
	return windowsServiceName
}

func configureWindowsServiceLogging() (*os.File, error) {
	dataDir := os.Getenv("USAGE_DATA_DIR")
	if dataDir == "" {
		exePath, err := os.Executable()
		if err != nil {
			return nil, err
		}
		dataDir = filepath.Join(filepath.Dir(exePath), "data")
	}
	if err := os.MkdirAll(dataDir, 0o755); err != nil {
		return nil, err
	}
	logPath := filepath.Join(dataDir, "cpa-manager.log")
	logFile, err := os.OpenFile(logPath, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0o644)
	if err != nil {
		return nil, err
	}
	log.SetOutput(io.MultiWriter(os.Stderr, logFile))
	return logFile, nil
}

func (windowsService) Execute(_ []string, requests <-chan svc.ChangeRequest, status chan<- svc.Status) (bool, uint32) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	errCh := make(chan error, 1)
	status <- svc.Status{State: svc.StartPending}
	go func() {
		errCh <- run(ctx)
	}()
	status <- svc.Status{State: svc.Running, Accepts: svc.AcceptStop | svc.AcceptShutdown}

	for {
		select {
		case request := <-requests:
			switch request.Cmd {
			case svc.Interrogate:
				status <- request.CurrentStatus
			case svc.Stop, svc.Shutdown:
				status <- svc.Status{State: svc.StopPending}
				cancel()
				if err := <-errCh; err != nil {
					log.Printf("service stopped with error: %v", err)
					status <- svc.Status{State: svc.Stopped}
					return false, 1
				}
				status <- svc.Status{State: svc.Stopped}
				return false, 0
			default:
				log.Printf("unexpected service control request: %v", request.Cmd)
			}
		case err := <-errCh:
			if err != nil {
				log.Printf("service failed: %v", err)
				status <- svc.Status{State: svc.Stopped}
				return false, 1
			}
			status <- svc.Status{State: svc.Stopped}
			return false, 0
		}
	}
}
