package main

import (
	"database/sql"
	"fmt"
	"log"
	"math/rand"
	"time"
	_ "github.com/denisenkom/go-mssqldb"
)

func GenerateRandomName() string {
	adjectives := []string{"Happy", "Clever", "Brave", "Eager", "Friendly", "Gentle", "Kind", "Lively", "Polite", "Witty"}
	nouns := []string{"Panda", "Tiger", "Dolphin", "Penguin", "Elephant", "Kangaroo", "Koala", "Giraffe", "Lion", "Zebra"}

	rand.Seed(time.Now().UnixNano())
	randomAdjective := adjectives[rand.Intn(len(adjectives))]
	randomNoun := nouns[rand.Intn(len(nouns))]

	return randomAdjective + " " + randomNoun
}

func main() {
	connString := "server={{EXTERNAL_LB_IP_OR_WORKER_IP, 1433_FOR_EXTERNAL_LB_30443_FOR_WORKER_IP}};user id=SA;password={{DB_PASSWORD}};database=db1"

	db, err := sql.Open("sqlserver", connString)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()
	for {
		randomName := GenerateRandomName()
		insertQuery := fmt.Sprintf("INSERT INTO Customers (name) VALUES ('%s')", randomName)
		_, err := db.Exec(insertQuery)
		if err != nil {
			log.Println("Error executing INSERT query:", err)
		}
		fmt.Printf("Inserted: %s\n", randomName)
		time.Sleep(200 * time.Millisecond)
	}
}
