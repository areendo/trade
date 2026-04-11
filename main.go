package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"sync"
	"time"
)

var (
	dataFile = "data.json"
	mu       sync.Mutex
)

type Snapshot struct {
	Time    int64   `json:"time"`
	Balance float64 `json:"balance"`
	Equity  float64 `json:"equity"`
}

type Position struct {
	Ticket    int64   `json:"ticket"`
	Symbol    string  `json:"symbol"`
	Type      string  `json:"type"`
	Volume    float64 `json:"volume"`
	OpenPrice float64 `json:"open_price"`
	Profit    float64 `json:"profit"`
}

type Deposit struct {
	Time   int64   `json:"time"`
	Amount float64 `json:"amount"`
}

type Data struct {
	Login     int64      `json:"login"`
	Balance   float64    `json:"balance"`
	Equity    float64    `json:"equity"`
	Positions []Position `json:"positions"`
	Deposits  []Deposit  `json:"deposits"`
	History   []Snapshot `json:"history"`
	LastSeen  int64      `json:"last_seen"`
}

func loadData() Data {
	var d Data

	b, err := os.ReadFile(dataFile)
	if err != nil {
		return d
	}
	if len(b) == 0 {
		return d
	}

	_ = json.Unmarshal(b, &d)
	return d
}

func saveData(d Data) error {
	b, err := json.MarshalIndent(d, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(dataFile, b, 0644)
}

func handleHome(w http.ResponseWriter, r *http.Request) {
	html, err := os.ReadFile("index.html")
	if err != nil {
		http.Error(w, "index.html not found", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	_, _ = w.Write(html)
}

func handleData(w http.ResponseWriter, r *http.Request) {
	mu.Lock()
	defer mu.Unlock()

	d := loadData()

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(d)
}

func handleUpdate(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var incoming Data
	if err := json.NewDecoder(r.Body).Decode(&incoming); err != nil {
		http.Error(w, "invalid json", http.StatusBadRequest)
		return
	}

	now := time.Now().Unix()

	mu.Lock()
	defer mu.Unlock()

	current := loadData()

	current.Login = incoming.Login
	current.Balance = incoming.Balance
	current.Equity = incoming.Equity
	current.Positions = incoming.Positions
	current.Deposits = incoming.Deposits
	current.LastSeen = now

	if incoming.Equity > 0 || incoming.Balance > 0 {
		current.History = append(current.History, Snapshot{
			Time:    now,
			Balance: incoming.Balance,
			Equity:  incoming.Equity,
		})
	}

	if len(current.History) > 500 {
		current.History = current.History[len(current.History)-500:]
	}

	if len(current.Deposits) > 500 {
		current.Deposits = current.Deposits[len(current.Deposits)-500:]
	}

	if err := saveData(current); err != nil {
		http.Error(w, "failed to save data", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write([]byte(`{"status":"ok"}`))
}

func main() {
	if _, err := os.Stat(dataFile); os.IsNotExist(err) {
		_ = os.WriteFile(dataFile, []byte(`{}`), 0644)
	}

	http.HandleFunc("/", handleHome)
	http.HandleFunc("/data", handleData)
	http.HandleFunc("/update", handleUpdate)

	log.Println("ArenTrade running on http://127.0.0.1:80")
	log.Fatal(http.ListenAndServe(":80", nil))
}