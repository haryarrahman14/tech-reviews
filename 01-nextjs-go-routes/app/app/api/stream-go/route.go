package main

import (
	"fmt"
	"net/http"
	"time"
)

func GET(w http.ResponseWriter, r *http.Request) {
	f, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "streaming unsupported", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	for i := 1; i <= 3; i++ {
		fmt.Fprintf(w, "Chunk %d\n", i)
		f.Flush()
		time.Sleep(200 * time.Millisecond)
	}
}
