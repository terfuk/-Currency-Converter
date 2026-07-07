// CurrencyConverter.cs
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;

class CurrencyConverter
{
    private static readonly HttpClient client = new HttpClient();
    private static readonly TimeSpan CacheTTL = TimeSpan.FromHours(1);
    private static Dictionary<string, double>? _rates = null;
    private static DateTime _timestamp = DateTime.MinValue;

    private static async Task<Dictionary<string, double>> FetchRatesAsync()
    {
        var response = await client.GetAsync("https://api.exchangerate.host/latest?base=USD");
        response.EnsureSuccessStatusCode();
        var json = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(json);
        var root = doc.RootElement;
        if (root.TryGetProperty("success", out var success) && success.GetBoolean() == false)
            throw new Exception("API returned success=false");
        var rates = root.GetProperty("rates");
        var dict = new Dictionary<string, double>();
        foreach (var prop in rates.EnumerateObject())
        {
            dict[prop.Name] = prop.Value.GetDouble();
        }
        return dict;
    }

    private static async Task<Dictionary<string, double>> GetRatesAsync()
    {
        var now = DateTime.UtcNow;
        if (_rates == null || (now - _timestamp) > CacheTTL)
        {
            Console.WriteLine("🔄 Fetching fresh exchange rates...");
            try
            {
                _rates = await FetchRatesAsync();
                _timestamp = now;
            }
            catch (Exception ex)
            {
                if (_rates == null)
                {
                    Console.WriteLine($"❌ Failed to fetch rates and no cache: {ex.Message}");
                    Environment.Exit(1);
                }
                Console.WriteLine("⚠️  Using cached rates (stale).");
            }
        }
        return _rates;
    }

    private static async Task<double> ConvertAsync(double amount, string fromCur, string toCur)
    {
        var rates = await GetRatesAsync();
        double usdAmount;
        if (fromCur == "USD")
            usdAmount = amount;
        else
        {
            if (!rates.ContainsKey(fromCur))
                throw new Exception($"Currency {fromCur} not supported.");
            usdAmount = amount / rates[fromCur];
        }
        if (toCur == "USD")
            return usdAmount;
        if (!rates.ContainsKey(toCur))
            throw new Exception($"Currency {toCur} not supported.");
        return usdAmount * rates[toCur];
    }

    private static async Task ShowCurrenciesAsync()
    {
        var rates = await GetRatesAsync();
        Console.WriteLine("\nAvailable currencies (rates vs USD):");
        foreach (var kv in rates)
        {
            Console.WriteLine($"  {kv.Key}: {kv.Value:F4}");
        }
    }

    static async Task Main()
    {
        Console.WriteLine("=== Currency Converter with Caching ===");
        while (true)
        {
            Console.WriteLine("\n1. Convert");
            Console.WriteLine("2. Show available currencies");
            Console.WriteLine("3. Refresh cache");
            Console.WriteLine("4. Exit");
            Console.Write("Choose: ");
            var choice = Console.ReadLine()?.Trim();
            switch (choice)
            {
                case "1":
                    Console.Write("Enter amount: ");
                    if (!double.TryParse(Console.ReadLine(), out double amount) || amount < 0)
                    {
                        Console.WriteLine("❌ Invalid amount.");
                        break;
                    }
                    Console.Write("From currency (e.g., USD): ");
                    var fromCur = Console.ReadLine()?.Trim().ToUpper() ?? "";
                    Console.Write("To currency (e.g., EUR): ");
                    var toCur = Console.ReadLine()?.Trim().ToUpper() ?? "";
                    try
                    {
                        var result = await ConvertAsync(amount, fromCur, toCur);
                        Console.WriteLine($"{amount:F2} {fromCur} = {result:F2} {toCur}");
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"❌ {ex.Message}");
                    }
                    break;
                case "2":
                    await ShowCurrenciesAsync();
                    break;
                case "3":
                    _rates = null;
                    Console.WriteLine("Cache cleared. Will refresh on next operation.");
                    break;
                case "4":
                    Console.WriteLine("Goodbye!");
                    return;
                default:
                    Console.WriteLine("Invalid choice.");
                    break;
            }
        }
    }
}
