package main

import (
	"encoding/json"
	"net/http"
)

type item struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

func GET(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(item{ID: r.PathValue("id"), Name: r.URL.Query().Get("name")})
}

func POST(w http.ResponseWriter, r *http.Request) {
	var in item
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1<<20)).Decode(&in); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}
	in.ID = r.PathValue("id")
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(in)
}
