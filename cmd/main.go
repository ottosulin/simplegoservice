package main

import (
	"log"
	"net/http"

	httpserver "github.com/ottosulin/simplegoservice/pkg"
)

func main() {
	err := httpserver.Initdb()
	if err != nil {
		log.Println("Errors interacting with the database, you probably chose not to use it: ", err)
	}
	http.HandleFunc("/hello", httpserver.Hello)
	http.HandleFunc("/headers", httpserver.Headers)

	err = http.ListenAndServe(":8080", nil)
	if err != nil {
		log.Fatalln("A critical error happened: ", err)
	}
}
