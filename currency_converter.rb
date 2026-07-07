# currency_converter.rb
require 'net/http'
require 'json'
require 'time'

CACHE_TTL = 3600 # 1 hour in seconds
$rates = nil
$timestamp = nil

def fetch_rates
  uri = URI('https://api.exchangerate.host/latest?base=USD')
  response = Net::HTTP.get_response(uri)
  raise "HTTP error: #{response.code}" unless response.is_a?(Net::HTTPSuccess)
  data = JSON.parse(response.body)
  raise "API error" unless data['success'] == true
  data['rates']
rescue => e
  puts "⚠️  Failed to fetch rates: #{e.message}"
  nil
end

def get_rates
  now = Time.now.to_i
  if $rates.nil? || $timestamp.nil? || (now - $timestamp) > CACHE_TTL
    puts "🔄 Fetching fresh exchange rates..."
    new_rates = fetch_rates
    if new_rates
      $rates = new_rates
      $timestamp = now
    else
      if $rates.nil?
        puts "❌ No cached data and API unavailable. Exiting."
        exit 1
      end
      puts "⚠️  Using cached rates (stale)."
    end
  end
  $rates
end

def convert(amount, from_cur, to_cur)
  rates = get_rates
  if from_cur == "USD"
    usd_amount = amount
  else
    from_rate = rates[from_cur]
    raise "Currency #{from_cur} not supported." if from_rate.nil?
    usd_amount = amount / from_rate
  end
  if to_cur == "USD"
    return usd_amount
  else
    to_rate = rates[to_cur]
    raise "Currency #{to_cur} not supported." if to_rate.nil?
    return usd_amount * to_rate
  end
end

def show_currencies
  rates = get_rates
  puts "\nAvailable currencies (rates vs USD):"
  rates.keys.sort.each do |curr|
    puts "  #{curr}: %.4f" % rates[curr]
  end
end

def main
  puts "=== Currency Converter with Caching ==="
  loop do
    puts "\n1. Convert"
    puts "2. Show available currencies"
    puts "3. Refresh cache"
    puts "4. Exit"
    print "Choose: "
    choice = gets.chomp.strip
    case choice
    when "1"
      print "Enter amount: "
      amount_str = gets.chomp
      begin
        amount = Float(amount_str)
      rescue
        puts "❌ Invalid amount."
        next
      end
      if amount < 0
        puts "❌ Amount must be positive."
        next
      end
      print "From currency (e.g., USD): "
      from_cur = gets.chomp.strip.upcase
      print "To currency (e.g., EUR): "
      to_cur = gets.chomp.strip.upcase
      begin
        result = convert(amount, from_cur, to_cur)
        puts "%.2f %s = %.2f %s" % [amount, from_cur, result, to_cur]
      rescue => e
        puts "❌ #{e.message}"
      end
    when "2"
      show_currencies
    when "3"
      $rates = nil
      $timestamp = nil
      puts "Cache cleared. Will refresh on next operation."
    when "4"
      puts "Goodbye!"
      break
    else
      puts "Invalid choice."
    end
  end
end

main if __FILE__ == $0
