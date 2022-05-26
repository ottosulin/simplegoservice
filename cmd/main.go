package main

import (
	"log"
	"net/http"

	httpserver "github.com/ottosulin/simplegoservice/pkg"
)

func main() {
	httpserver.Initdb()
	http.HandleFunc("/hello", httpserver.Hello)
	http.HandleFunc("/headers", httpserver.Headers)

	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		log.Fatalln("Error happened: ", err)
	}
}
