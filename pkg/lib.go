package httpserver

import (
	"fmt"
	"log"
	"net/http"
	"time"
)

func Hello(w http.ResponseWriter, req *http.Request) {
	fmt.Fprintf(w, "hello world\n")
}

func Headers(w http.ResponseWriter, req *http.Request) {
	for name, headers := range req.Header {
		for _, h := range headers {
			fmt.Fprintf(w, "%v: %v\n", name, h)
		}
	}
	db, err := openDB()
	if err != nil {
		// We're fine running without the database
		log.Println("Can't get the DB: ", err)
	} else {
		var accounts []Account
		db.Find(&accounts)
		fmt.Fprintf(w, "Balance at '%s':\n", time.Now())
		for _, account := range accounts {
			fmt.Fprintf(w, "%s %d\n", account.ID, account.Balance)
		}
	}

}
