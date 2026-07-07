# 💱 Currency Converter – with Caching

A powerful **multi‑language currency converter** that fetches live exchange rates from a public API and caches them for up to 1 hour.  
Built to demonstrate clean code, API integration, and robust caching across **7 programming languages**.

## ✨ Features
- **Live rates** – uses the free [ExchangeRate.host](https://exchangerate.host) API (no API key required).
- **Smart caching** – rates are stored in memory with a timestamp; stale data is automatically refreshed.
- **Cross‑currency conversion** – converts any amount between 20+ currencies (USD, EUR, RUB, GBP, JPY, etc.).
- **Interactive CLI** – choose from a menu:
  - `1` – Convert currency
  - `2` – Show all available currencies (with current rates relative to USD)
  - `3` – Refresh cache manually
  - `4` – Exit
- **Error resilience** – falls back to cached rates if the API is unavailable (with a warning).
- **Precise output** – results rounded to 2 decimal places.

## 🗂 Languages & Files
| Language          | File                     |
|-------------------|--------------------------|
| Python            | `currency_converter.py`  |
| Go                | `currency_converter.go`  |
| JavaScript (Node) | `currency_converter.js`  |
| C#                | `CurrencyConverter.cs`   |
| Java              | `CurrencyConverter.java` |
| Ruby              | `currency_converter.rb`  |
| Swift             | `currency_converter.swift`|

## 🚀 How to Run
Each file is standalone – just run it with the appropriate interpreter or compiler:

| Language | Command |
|----------|---------|
| Python   | `python currency_converter.py` |
| Go       | `go run currency_converter.go` |
| JavaScript | `node currency_converter.js` |
| C#       | `dotnet run` or `csc CurrencyConverter.cs` |
| Java     | `javac CurrencyConverter.java && java CurrencyConverter` |
| Ruby     | `ruby currency_converter.rb` |
| Swift    | `swift currency_converter.swift` |

> ⚠️ **Internet access** is required for the initial fetch. Subsequent conversions use the cached rates.

## 📊 Example Session
=== Currency Converter with Caching ===

Convert

Show available currencies

Refresh cache

Exit
Choose: 1
Enter amount: 100
From currency (e.g., USD): USD
To currency (e.g., EUR): EUR
100.00 USD = 92.45 EUR (rate: 0.9245)

text

## 🔧 Technical Details
- **Cache TTL**: 1 hour (configurable).
- **Base currency**: all rates are stored relative to USD (USD is the anchor).
- **API endpoint**: `https://api.exchangerate.host/latest?base=USD`
- **Fallback**: if the API fails, the last cached rates are used (if any).

## 🤝 Contributing
Feel free to add more languages or improve the caching logic – pull requests are welcome!

## 📜 License
MIT – use it freely.
