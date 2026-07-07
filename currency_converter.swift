// currency_converter.swift
import Foundation

let CACHE_TTL: TimeInterval = 3600 // 1 hour
var cachedRates: [String: Double]?
var cacheTimestamp: Date?

func fetchRates() -> [String: Double]? {
    let url = URL(string: "https://api.exchangerate.host/latest?base=USD")!
    let semaphore = DispatchSemaphore(value: 0)
    var result: [String: Double]?
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        defer { semaphore.signal() }
        guard let data = data, error == nil else { return }
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let success = json?["success"] as? Bool, success == false {
                return
            }
            if let rates = json?["rates"] as? [String: Double] {
                result = rates
            }
        } catch {
            // ignore
        }
    }
    task.resume()
    semaphore.wait()
    return result
}

func getRates() -> [String: Double] {
    let now = Date()
    if cachedRates == nil || cacheTimestamp == nil || now.timeIntervalSince(cacheTimestamp!) > CACHE_TTL {
        print("🔄 Fetching fresh exchange rates...")
        if let newRates = fetchRates() {
            cachedRates = newRates
            cacheTimestamp = now
        } else {
            if cachedRates == nil {
                print("❌ Failed to fetch rates and no cache. Exiting.")
                exit(1)
            }
            print("⚠️  Using cached rates (stale).")
        }
    }
    return cachedRates!
}

func convert(amount: Double, from fromCur: String, to toCur: String) throws -> Double {
    let rates = getRates()
    var usdAmount: Double
    if fromCur == "USD" {
        usdAmount = amount
    } else {
        guard let fromRate = rates[fromCur] else {
            throw NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "Currency \(fromCur) not supported."])
        }
        usdAmount = amount / fromRate
    }
    if toCur == "USD" {
        return usdAmount
    }
    guard let toRate = rates[toCur] else {
        throw NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "Currency \(toCur) not supported."])
    }
    return usdAmount * toRate
}

func showCurrencies() {
    let rates = getRates()
    print("\nAvailable currencies (rates vs USD):")
    for (curr, rate) in rates.sorted(by: { $0.key < $1.key }) {
        print("  \(curr): \(String(format: "%.4f", rate))")
    }
}

func main() {
    print("=== Currency Converter with Caching ===")
    while true {
        print("\n1. Convert")
        print("2. Show available currencies")
        print("3. Refresh cache")
        print("4. Exit")
        print("Choose: ", terminator: "")
        guard let choice = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { continue }
        switch choice {
        case "1":
            print("Enter amount: ", terminator: "")
            guard let amountStr = readLine(), let amount = Double(amountStr), amount >= 0 else {
                print("❌ Invalid amount.")
                continue
            }
            print("From currency (e.g., USD): ", terminator: "")
            let fromCur = readLine()?.trimmingCharacters(in: .whitespaces).uppercased() ?? ""
            print("To currency (e.g., EUR): ", terminator: "")
            let toCur = readLine()?.trimmingCharacters(in: .whitespaces).uppercased() ?? ""
            do {
                let result = try convert(amount: amount, from: fromCur, to: toCur)
                print(String(format: "%.2f %@ = %.2f %@", amount, fromCur, result, toCur))
            } catch {
                print("❌ \(error.localizedDescription)")
            }
        case "2":
            showCurrencies()
        case "3":
            cachedRates = nil
            cacheTimestamp = nil
            print("Cache cleared. Will refresh on next operation.")
        case "4":
            print("Goodbye!")
            return
        default:
            print("Invalid choice.")
        }
    }
}

main()
