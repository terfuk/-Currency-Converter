// currency_converter.go
package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

type RatesResponse struct {
	Success bool               `json:"success"`
	Rates   map[string]float64 `json:"rates"`
}

var cache struct {
	rates     map[string]float64
	timestamp time.Time
}
var ttl = 1 * time.Hour

func fetchRates() (map[string]float64, error) {
	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Get("https://api.exchangerate.host/latest?base=USD")
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	var data RatesResponse
	if err := json.Unmarshal(body, &data); err != nil {
		return nil, err
	}
	if !data.Success {
		return nil, fmt.Errorf("API returned success=false")
	}
	return data.Rates, nil
}

func getRates() map[string]float64 {
	if cache.rates == nil || time.Since(cache.timestamp) > ttl {
		fmt.Println("🔄 Fetching fresh exchange rates...")
		newRates, err := fetchRates()
		if err == nil {
			cache.rates = newRates
			cache.timestamp = time.Now()
		} else {
			if cache.rates == nil {
				fmt.Printf("❌ Failed to fetch rates and no cache: %v\n", err)
				os.Exit(1)
			}
			fmt.Println("⚠️  Using cached rates (stale).")
		}
	}
	return cache.rates
}

func convert(amount float64, fromCur, toCur string) (float64, error) {
	rates := getRates()
	var usdAmount float64
	if fromCur == "USD" {
		usdAmount = amount
	} else {
		rate, ok := rates[fromCur]
		if !ok {
			return 0, fmt.Errorf("currency %s not supported", fromCur)
		}
		usdAmount = amount / rate
	}
	if toCur == "USD" {
		return usdAmount, nil
	}
	rate, ok := rates[toCur]
	if !ok {
		return 0, fmt.Errorf("currency %s not supported", toCur)
	}
	return usdAmount * rate, nil
}

func showCurrencies() {
	rates := getRates()
	fmt.Println("\nAvailable currencies (rates vs USD):")
	for curr, rate := range rates {
		fmt.Printf("  %s: %.4f\n", curr, rate)
	}
}

func main() {
	reader := bufio.NewReader(os.Stdin)
	fmt.Println("=== Currency Converter with Caching ===")

	for {
		fmt.Println("\n1. Convert")
		fmt.Println("2. Show available currencies")
		fmt.Println("3. Refresh cache")
		fmt.Println("4. Exit")
		fmt.Print("Choose: ")
		choice, _ := reader.ReadString('\n')
		choice = strings.TrimSpace(choice)

		switch choice {
		case "1":
			fmt.Print("Enter amount: ")
			amountStr, _ := reader.ReadString('\n')
			amount, err := strconv.ParseFloat(strings.TrimSpace(amountStr), 64)
			if err != nil {
				fmt.Println("❌ Invalid amount.")
				continue
			}
			fmt.Print("From currency (e.g., USD): ")
			fromCur, _ := reader.ReadString('\n')
			fromCur = strings.TrimSpace(strings.ToUpper(fromCur))
			fmt.Print("To currency (e.g., EUR): ")
			toCur, _ := reader.ReadString('\n')
			toCur = strings.TrimSpace(strings.ToUpper(toCur))

			result, err := convert(amount, fromCur, toCur)
			if err != nil {
				fmt.Printf("❌ %v\n", err)
			} else {
				fmt.Printf("%.2f %s = %.2f %s\n", amount, fromCur, result, toCur)
			}
		case "2":
			showCurrencies()
		case "3":
			cache.rates = nil
			fmt.Println("Cache cleared. Will refresh on next operation.")
		case "4":
			fmt.Println("Goodbye!")
			return
		default:
			fmt.Println("Invalid choice.")
		}
	}
}
