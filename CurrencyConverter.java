// CurrencyConverter.java
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

public class CurrencyConverter {
    private static Map<String, Double> rates = null;
    private static Instant timestamp = null;
    private static final Duration CACHE_TTL = Duration.ofHours(1);

    public static Map<String, Double> fetchRates() throws Exception {
        String urlStr = "https://api.exchangerate.host/latest?base=USD";
        URL url = new URL(urlStr);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("GET");
        conn.setConnectTimeout(5000);
        conn.setReadTimeout(5000);

        if (conn.getResponseCode() != 200) {
            throw new RuntimeException("HTTP error: " + conn.getResponseCode());
        }

        try (BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream()))) {
            String json = br.lines().collect(Collectors.joining());
            // Naive JSON parsing – assuming format: {"success":true,"rates":{"USD":1.0,...}}
            // For production, use a JSON library (Jackson/Gson). We'll do simple parsing.
            // We'll parse manually for brevity.
            if (!json.contains("\"success\":true")) {
                throw new RuntimeException("API returned success=false");
            }
            // Extract rates object
            int ratesStart = json.indexOf("\"rates\":{") + 8;
            int ratesEnd = json.lastIndexOf("}");
            String ratesJson = json.substring(ratesStart, ratesEnd);
            // Split by comma, but careful: values contain commas? Not in numbers.
            Map<String, Double> result = new HashMap<>();
            // Remove leading/trailing braces
            ratesJson = ratesJson.trim();
            if (ratesJson.startsWith("{")) ratesJson = ratesJson.substring(1);
            if (ratesJson.endsWith("}")) ratesJson = ratesJson.substring(0, ratesJson.length()-1);
            String[] pairs = ratesJson.split(",");
            for (String pair : pairs) {
                String[] kv = pair.split(":");
                if (kv.length == 2) {
                    String key = kv[0].trim().replaceAll("\"", "");
                    double value = Double.parseDouble(kv[1].trim());
                    result.put(key, value);
                }
            }
            return result;
        }
    }

    public static Map<String, Double> getRates() {
        Instant now = Instant.now();
        if (rates == null || timestamp == null || Duration.between(timestamp, now).compareTo(CACHE_TTL) > 0) {
            System.out.println("🔄 Fetching fresh exchange rates...");
            try {
                rates = fetchRates();
                timestamp = now;
            } catch (Exception e) {
                if (rates == null) {
                    System.err.println("❌ Failed to fetch rates and no cache: " + e.getMessage());
                    System.exit(1);
                }
                System.out.println("⚠️  Using cached rates (stale).");
            }
        }
        return rates;
    }

    public static double convert(double amount, String fromCur, String toCur) throws Exception {
        Map<String, Double> rates = getRates();
        double usdAmount;
        if (fromCur.equals("USD")) {
            usdAmount = amount;
        } else {
            Double fromRate = rates.get(fromCur);
            if (fromRate == null) throw new Exception("Currency " + fromCur + " not supported.");
            usdAmount = amount / fromRate;
        }
        if (toCur.equals("USD")) return usdAmount;
        Double toRate = rates.get(toCur);
        if (toRate == null) throw new Exception("Currency " + toCur + " not supported.");
        return usdAmount * toRate;
    }

    public static void showCurrencies() {
        Map<String, Double> rates = getRates();
        System.out.println("\nAvailable currencies (rates vs USD):");
        rates.entrySet().stream().sorted(Map.Entry.comparingByKey())
                .forEach(e -> System.out.printf("  %s: %.4f%n", e.getKey(), e.getValue()));
    }

    public static void main(String[] args) throws Exception {
        Scanner scanner = new Scanner(System.in);
        System.out.println("=== Currency Converter with Caching ===");
        while (true) {
            System.out.println("\n1. Convert");
            System.out.println("2. Show available currencies");
            System.out.println("3. Refresh cache");
            System.out.println("4. Exit");
            System.out.print("Choose: ");
            String choice = scanner.nextLine().trim();
            switch (choice) {
                case "1":
                    System.out.print("Enter amount: ");
                    double amount;
                    try {
                        amount = Double.parseDouble(scanner.nextLine().trim());
                    } catch (NumberFormatException e) {
                        System.out.println("❌ Invalid amount.");
                        continue;
                    }
                    if (amount < 0) {
                        System.out.println("❌ Amount must be positive.");
                        continue;
                    }
                    System.out.print("From currency (e.g., USD): ");
                    String fromCur = scanner.nextLine().trim().toUpperCase();
                    System.out.print("To currency (e.g., EUR): ");
                    String toCur = scanner.nextLine().trim().toUpperCase();
                    try {
                        double result = convert(amount, fromCur, toCur);
                        System.out.printf("%.2f %s = %.2f %s%n", amount, fromCur, result, toCur);
                    } catch (Exception e) {
                        System.out.println("❌ " + e.getMessage());
                    }
                    break;
                case "2":
                    showCurrencies();
                    break;
                case "3":
                    rates = null;
                    timestamp = null;
                    System.out.println("Cache cleared. Will refresh on next operation.");
                    break;
                case "4":
                    System.out.println("Goodbye!");
                    scanner.close();
                    return;
                default:
                    System.out.println("Invalid choice.");
            }
        }
    }
}
