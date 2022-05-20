package main

import (
	"net/http"

	httpserver "github.com/ottosulin/simplegoservice/pkg"
)

func main() {
	http.HandleFunc("/hello", httpserver.Hello)
	http.HandleFunc("/headers", httpserver.Headers)

	http.ListenAndServe(":8080", nil)
}
