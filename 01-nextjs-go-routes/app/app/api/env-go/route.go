package main

import (
	"fmt"
	"net/http"
	"os"
	"runtime"
)

// Shows what a Go worker sees: its own process id, the cores Go will use, and one environment variable.
func GET(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, `{"pid":%d,"gomaxprocs":%d,"cpus":%d,"GOMAXPROCS_env":%q}`,
		os.Getpid(), runtime.GOMAXPROCS(0), runtime.NumCPU(), os.Getenv("GOMAXPROCS"))
}
