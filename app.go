package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"

	"github.com/gorilla/mux"
)

func main() {
	r := mux.NewRouter()

	// The k8s ingress controller wants to see a 200 returned from / as a primitive healthcheck
	// Without this,  the ingress controller will report "Some backend services are in UNHEALTHY state"
	r.Path("/").Methods("GET").
		HandlerFunc(rootHandler)

	r.Path("/hello").Methods("GET").
		HandlerFunc(helloHandler)

	r.Path("/hello/world").Methods("GET").
		HandlerFunc(helloHandler2)

	http.Handle("/", r)
	port := 8080
	if portStr := os.Getenv("PORT"); portStr != "" {
		port, _ = strconv.Atoi(portStr)
	}
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%d", port), nil))
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
	b := []byte{}
	w.Write(b)
}

func helloHandler(w http.ResponseWriter, r *http.Request) {
	type Answer struct {
		Message string
	}
	msg := Answer {
		Message: "hello world",
	}

	b, err := json.Marshal(msg)
	if err != nil {
		errorf(w, http.StatusInternalServerError, "Could not marshal JSON: %v", err)
		return
	}
	w.Write(b)
}

func helloHandler2(w http.ResponseWriter, r *http.Request) {
	type Answer struct {
		Message string
	}
	msg := Answer {
		Message: "hello worldling",
	}

	b, err := json.Marshal(msg)
	if err != nil {
		errorf(w, http.StatusInternalServerError, "Could not marshal JSON: %v", err)
		return
	}
	w.Write(b)
}

// corsHandler wraps a HTTP handler and applies the appropriate responses for Cross-Origin Resource Sharing.
type corsHandler http.HandlerFunc

func (h corsHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	if r.Method == "OPTIONS" {
		w.Header().Set("Access-Control-Allow-Headers", "Authorization")
		return
	}
	h(w, r)
}

// errorf writes a swagger-compliant error response.
func errorf(w http.ResponseWriter, code int, format string, a ...interface{}) {
	var out struct {
		Code    int    `json:"code"`
		Message string `json:"message"`
	}

	out.Code = code
	out.Message = fmt.Sprintf(format, a...)

	b, err := json.Marshal(out)
	if err != nil {
		http.Error(w, `{"code": 500, "message": "Could not format JSON for original message."}`, 500)
		return
	}

	http.Error(w, string(b), code)
}
