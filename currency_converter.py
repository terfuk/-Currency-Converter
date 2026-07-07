# currency_converter.py
import requests
import json
from datetime import datetime, timedelta
import time

CACHE_TTL = timedelta(hours=1)
CACHE = {"rates": None, "timestamp": None}

def fetch_rates():
    """Fetch latest USD‑based rates from exchangerate.host."""
    try:
        resp = requests.get("https://api.exchangerate.host/latest?base=USD", timeout=5)
        resp.raise_for_status()
        data = resp.json()
        if data.get("success") is False:
            raise ValueError("API returned error")
        return data["rates"]
    except Exception as e:
        print(f"⚠️  Failed to fetch rates: {e}")
        return None

def get_rates():
    """Return cached rates, refreshing if stale or missing."""
    now = datetime.now()
    if CACHE["rates"] is None or (now - CACHE["timestamp"]) > CACHE_TTL:
        print("🔄 Fetching fresh exchange rates...")
        new_rates = fetch_rates()
        if new_rates is not None:
            CACHE["rates"] = new_rates
            CACHE["timestamp"] = now
        else:
            if CACHE["rates"] is None:
                print("❌ No cached data and API unavailable. Exiting.")
                exit(1)
            print("⚠️  Using cached rates (stale).")
    return CACHE["rates"]

def convert(amount, from_cur, to_cur):
    rates = get_rates()
    if from_cur == "USD":
        usd_amount = amount
    else:
        if from_cur not in rates:
            return None, f"Currency {from_cur} not supported."
        usd_amount = amount / rates[from_cur]  # convert to USD
    if to_cur == "USD":
        result = usd_amount
    else:
        if to_cur not in rates:
            return None, f"Currency {to_cur} not supported."
        result = usd_amount * rates[to_cur]
    return round(result, 2), None

def show_currencies():
    rates = get_rates()
    print("\nAvailable currencies (rates vs USD):")
    for curr, rate in sorted(rates.items()):
        print(f"  {curr}: {rate:.4f}")

def main():
    print("=== Currency Converter with Caching ===")
    while True:
        print("\n1. Convert")
        print("2. Show available currencies")
        print("3. Refresh cache")
        print("4. Exit")
        choice = input("Choose: ").strip()
        if choice == "1":
            try:
                amount = float(input("Enter amount: "))
                from_cur = input("From currency (e.g., USD): ").upper()
                to_cur = input("To currency (e.g., EUR): ").upper()
                result, err = convert(amount, from_cur, to_cur)
                if err:
                    print(f"❌ {err}")
                else:
                    print(f"{amount:.2f} {from_cur} = {result:.2f} {to_cur}")
            except ValueError:
                print("❌ Invalid amount.")
        elif choice == "2":
            show_currencies()
        elif choice == "3":
            CACHE["rates"] = None  # force refresh on next get
            print("Cache cleared. Will refresh on next operation.")
        elif choice == "4":
            print("Goodbye!")
            break
        else:
            print("Invalid choice.")

if __name__ == "__main__":
    main()
