package httpserver

import (
	"context"
	"flag"
	"fmt"
	"log"
	"math/rand"
	"time"

	"github.com/cockroachdb/cockroach-go/v2/crdb/crdbgorm"
	"github.com/google/uuid"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// Account is our model, which corresponds to the "accounts" table
type Account struct {
	ID      uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4()"`
	Balance int
}

// The `acctIDs` global variable tracks the random IDs generated by `addAccounts`
var acctIDs []uuid.UUID

// Insert new rows into the "accounts" table
// This function generates new UUIDs and random balances for each row, and
// then it appends the ID to the `acctIDs`, which other functions use to track the IDs
func addAccounts(db *gorm.DB, numRows int, transferAmount int) error {
	log.Printf("Creating %d new accounts...", numRows)
	for i := 0; i < numRows; i++ {
		newID := uuid.New()
		newBalance := rand.Intn(10000) + transferAmount
		if err := db.Create(&Account{ID: newID, Balance: newBalance}).Error; err != nil {
			return err
		}
		acctIDs = append(acctIDs, newID)
	}
	log.Println("Accounts created.")
	return nil
}

// Transfer funds between accounts
// This function adds `amount` to the "balance" column of the row with the "id" column matching `toID`,
// and removes `amount` from the "balance" column of the row with the "id" column matching `fromID`
func transferFunds(db *gorm.DB, fromID uuid.UUID, toID uuid.UUID, amount int) error {
	log.Printf("Transferring %d from account %s to account %s...", amount, fromID, toID)
	var fromAccount Account
	var toAccount Account

	db.First(&fromAccount, fromID)
	db.First(&toAccount, toID)

	if fromAccount.Balance < amount {
		return fmt.Errorf("account %s balance %d is lower than transfer amount %d", fromAccount.ID, fromAccount.Balance, amount)
	}

	fromAccount.Balance -= amount
	toAccount.Balance += amount

	if err := db.Save(&fromAccount).Error; err != nil {
		return err
	}
	if err := db.Save(&toAccount).Error; err != nil {
		return err
	}
	log.Println("Funds transferred.")
	return nil
}

// Print IDs and balances for all rows in "accounts" table
func printBalances(db *gorm.DB) {
	var accounts []Account
	db.Find(&accounts)
	fmt.Printf("Balance at '%s':\n", time.Now())
	for _, account := range accounts {
		fmt.Printf("%s %d\n", account.ID, account.Balance)
	}
}

// Delete all rows in "accounts" table inserted by `main` (i.e., tracked by `acctIDs`)
func deleteAccounts(db *gorm.DB, accountIDs []uuid.UUID) error {
	log.Println("Deleting accounts created...")
	err := db.Where("id IN ?", accountIDs).Delete(Account{}).Error
	if err != nil {
		return err
	}
	log.Println("Accounts deleted.")
	return nil
}

var (
	addr = flag.String("addr", "postgresql://root@cockroachdb-public:26257?sslmode=require&sslrootcert=/cockroach/cockroach-certs/ca.crt&sslcert=/cockroach/cockroach-certs/client.root.crt&sslkey=/cockroach/cockroach-certs/client.root.key", "the address of the database")
)

func openDB() (*gorm.DB, error) {
	db, err := gorm.Open(postgres.Open(*addr), &gorm.Config{})
	if err != nil {
		return nil, err
	}
	return db, nil
}

func Initdb() {

	db, err := gorm.Open(postgres.Open(*addr), &gorm.Config{})
	if err != nil {
		log.Fatal(err)
	}

	// Automatically create the "accounts" table based on the `Account`
	// model.
	db.AutoMigrate(&Account{})

	// The number of initial rows to insert
	const numAccts int = 5

	// The amount to be transferred between two accounts.
	const transferAmt int = 100

	// Insert `numAccts` rows into the "accounts" table.
	// To handle potential transaction retry errors, we wrap the call
	// to `addAccounts` in `crdbgorm.ExecuteTx`, a helper function for
	// GORM which implements a retry loop
	if err := crdbgorm.ExecuteTx(context.Background(), db, nil,
		func(tx *gorm.DB) error {
			return addAccounts(db, numAccts, transferAmt)
		},
	); err != nil {
		// For information and reference documentation, see:
		//   https://www.cockroachlabs.com/docs/stable/error-handling-and-troubleshooting.html
		fmt.Println(err)
	}

	// Print balances before transfer.
	//printBalances(db)

	// Select two account IDs
	fromID := acctIDs[0]
	toID := acctIDs[0:][rand.Intn(len(acctIDs))]

	// Transfer funds between accounts.  To handle potential
	// transaction retry errors, we wrap the call to `transferFunds`
	// in `crdbgorm.ExecuteTx`
	if err := crdbgorm.ExecuteTx(context.Background(), db, nil,
		func(tx *gorm.DB) error {
			return transferFunds(tx, fromID, toID, transferAmt)
		},
	); err != nil {
		// For information and reference documentation, see:
		//   https://www.cockroachlabs.com/docs/stable/error-handling-and-troubleshooting.html
		fmt.Println(err)
	}

	// Print balances after transfer to ensure that it worked.
	//printBalances(db)

	// Delete all accounts created by the earlier call to `addAccounts`
	// To handle potential transaction retry errors, we wrap the call
	// to `deleteAccounts` in `crdbgorm.ExecuteTx`
	// if err := crdbgorm.ExecuteTx(context.Background(), db, nil,
	// 	func(tx *gorm.DB) error {
	// 		return deleteAccounts(db, acctIDs)
	// 	},
	// ); err != nil {
	// 	// For information and reference documentation, see:
	// 	//   https://www.cockroachlabs.com/docs/stable/error-handling-and-troubleshooting.html
	// 	fmt.Println(err)
	// }
}
