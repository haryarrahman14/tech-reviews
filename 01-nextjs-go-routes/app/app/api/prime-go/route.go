package main

import (
	"fmt"
	"net/http"
	"strconv"
)

func GET(w http.ResponseWriter, r *http.Request) {
	n, _ := strconv.Atoi(r.URL.Query().Get("n"))
	if n > 5_000_000 {
		n = 5_000_000
	}
	count := 0
	for i := 2; i < n; i++ {
		prime := true
		for j := 2; j*j <= i; j++ {
			if i%j == 0 {
				prime = false
				break
			}
		}
		if prime {
			count++
		}
	}
	fmt.Fprintf(w, `{"n":%d,"primes":%d}`, n, count)
}
