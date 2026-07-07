// currency_converter.js
const readline = require('readline');
const https = require('https');

const CACHE_TTL = 60 * 60 * 1000; // 1 hour in ms
let cache = { rates: null, timestamp: null };

function fetchRates() {
    return new Promise((resolve, reject) => {
        const url = 'https://api.exchangerate.host/latest?base=USD';
        https.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const json = JSON.parse(data);
                    if (json.success === false) reject(new Error('API error'));
                    resolve(json.rates);
                } catch (e) {
                    reject(e);
                }
            });
        }).on('error', reject);
    });
}

async function getRates() {
    const now = Date.now();
    if (!cache.rates || (now - cache.timestamp) > CACHE_TTL) {
        console.log('🔄 Fetching fresh exchange rates...');
        try {
            const newRates = await fetchRates();
            cache.rates = newRates;
            cache.timestamp = now;
        } catch (err) {
            if (!cache.rates) {
                console.error(`❌ Failed to fetch rates and no cache: ${err.message}`);
                process.exit(1);
            }
            console.log('⚠️  Using cached rates (stale).');
        }
    }
    return cache.rates;
}

async function convert(amount, fromCur, toCur) {
    const rates = await getRates();
    let usdAmount;
    if (fromCur === 'USD') {
        usdAmount = amount;
    } else {
        if (!rates[fromCur]) throw new Error(`Currency ${fromCur} not supported.`);
        usdAmount = amount / rates[fromCur];
    }
    if (toCur === 'USD') return usdAmount;
    if (!rates[toCur]) throw new Error(`Currency ${toCur} not supported.`);
    return usdAmount * rates[toCur];
}

async function showCurrencies() {
    const rates = await getRates();
    console.log('\nAvailable currencies (rates vs USD):');
    for (const [curr, rate] of Object.entries(rates).sort()) {
        console.log(`  ${curr}: ${rate.toFixed(4)}`);
    }
}

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

function ask(query) {
    return new Promise(resolve => rl.question(query, resolve));
}

async function main() {
    console.log('=== Currency Converter with Caching ===');
    while (true) {
        console.log('\n1. Convert');
        console.log('2. Show available currencies');
        console.log('3. Refresh cache');
        console.log('4. Exit');
        const choice = await ask('Choose: ');
        if (choice === '1') {
            const amountStr = await ask('Enter amount: ');
            const amount = parseFloat(amountStr);
            if (isNaN(amount) || amount < 0) {
                console.log('❌ Invalid amount.');
                continue;
            }
            const fromCur = (await ask('From currency (e.g., USD): ')).toUpperCase();
            const toCur = (await ask('To currency (e.g., EUR): ')).toUpperCase();
            try {
                const result = await convert(amount, fromCur, toCur);
                console.log(`${amount.toFixed(2)} ${fromCur} = ${result.toFixed(2)} ${toCur}`);
            } catch (err) {
                console.log(`❌ ${err.message}`);
            }
        } else if (choice === '2') {
            await showCurrencies();
        } else if (choice === '3') {
            cache.rates = null;
            console.log('Cache cleared. Will refresh on next operation.');
        } else if (choice === '4') {
            console.log('Goodbye!');
            rl.close();
            break;
        } else {
            console.log('Invalid choice.');
        }
    }
}

main().catch(console.error);
