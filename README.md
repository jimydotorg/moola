# Moola

Manage your crypto Moola on Coinbase/GDAX.

## Getting Started

### Prerequisites

* Elixir
* Postgres
* Your GDAX API key
* Optional: Coinbase, Binance API keys

### Configuration

    cp config/dev.secret.exs.sample config/dev.secret.exs
    cp config/prod.secret.exs.sample config/prod.secret.exs

Set your API keys via `config/*.secret.exs`, which points to shell environment variables. Personally, I stick mine in a `.envrc` file which is automatically loaded using [direnv](https://direnv.net).

Sample `.envrc` file:

	export GDAX_API_KEY="..."
	export GDAX_API_SECRET="..."
	export GDAX_API_PASSPHRASE="lamboslamboslambos"
	
	export COINBASE_API_KEY="..."
	export COINBASE_API_SECRET="..."
	
	export BINANCE_API_KEY="..."
	export BINANCE_API_SECRET="..."

Make sure your database info in `config/*.secret.exs` is set correctly.

Fetch dependencies: 

	mix deps.get

Create database tables: 

	mix db.reset

If that succeeded, fire it up:

    iex -S mix

Success looks like this:

	Connected!
	[Start GDAXSocket] true
	Interactive Elixir (1.5.2) - press Ctrl+C to exit (type h() ENTER for help)
	iex(1)> 

This indicates you have successfully connected to the GDAX websocket, and are ready to play crypto.

## Buying/selling w/o fees

Buy/sell orders are always placed as "Post Only", which means that a taker fee is never incurred. The bid is placed at the edge of the order book (i.e., at the lowest ask price or highest bid price) However, because it not a taker order, the order may take a little while to fill, or never at all. If the spot prices changes while waiting for the order to be filled, you can submit a new order. Moola will cancel existing orders before placing a new one.

From the iex console, run:

	Moola.GDAX.buy_fixed_dollars("eth-usd", 13.37)
	Moola.GDAX.sell_fixed_dollars("eth-usd", 13.37)

## Dollar Cost Buying

DollarBuyer lets you buy a fixed dollar amount over a specified time period. 

Set the buy parameters in `config/*.secret.exs`

    config :moola, Moola.DollarBuyer,
      auto_start: false,
      buy_targets: ["eth-usd": 25.0, "btc-usd": 25.0, "bch-usd": 13.37],
      buy_period_seconds: 300,
      min_usd_balance: 100.00

The DollarBuyer can automatically run upon startup (`auto_start: true`), or can be started manually:

	Moola.DollarBuyer.start!

In the example above, the DollarBuyer will attempt to purchase $25 USD of ETH, $25 of BTC, and $13.37 of BCH every 300 seconds (5 minutes). It will do so only if there is at least $100 in your GDAX account.

## GDAXSocket and GDAXState

Moola.GDAXSocket listens to the GDAX websocket feed to provide real-time updates. Data points are logged every 15 seconds to the local database. Real-time updates are written to GDAXState, which provides quotes to the DollarBuyer.

The websocket subscriptions and url can be changed in `config/(dev|prod).exs`

    config :moola, Moola.GDAXSocket,
      socket_url: "wss://ws-feed.gdax.com/",
      ticker_period: 15.0,
      product_ids: ["ETH-USD", "BTC-USD", "LTC-USD", "ETH-BTC", "BCH-USD"]

## Coinbase & Binance

There is an optional process, CoinbaseWatcher, that only writes ticker data to the database. Moola does not support buys/sells through Coinbase, because that'd be stupid. 

There are also optional BinanceState and BinanceSocket processes which are analogous to GDAXState and GDAXSocket. Binance ticker data is logged to the database, but buying/selling is not supported yet.

If you want to run these optional processes, uncomment the lines referencing them in `lib/moola/application.ex`

## Notes

Numbers are often handled as Decimals (sometimes aliased as "D"), which results in greater accuracy, but worse code readability. See: https://hexdocs.pm/decimal/readme.html

Bids for fixed dollar buy orders are based on the current order book, and is somewhat convoluted. Read the code for Moola.GDAX.buy_fixed_dollars yourself. It is the result of a bunch of trial and error, and by no means optimal or even good.

One very important thing to keep in mind is that your bid should be based on the most current info available. If your price data is even a few seconds out of date, you will run into problems. This is why `buy_fixed_dollars` checks the timestamp on the price quote before placing an order.

"ZX.i" is my stupid function for printing debug statements, and is littered everywhere in the code. It's quicker than typing "IO.inspect"

## Known issues

Autobuys works only when buying USD, so it can't be used for ETH-BTC. This is due mainly to the precision/formatting of bid prices, so that would need to be changed in order to support ETH-BTC exchange.

There is a bunch of unused code to support non-yet-existent frontend clients. (User, ClientToken, UserToken, etc) Probably best to ignore it.

## Unknown issues

Unknown, but there are probably many.

## Dependencies

  * GDAX API adapter: https://github.com/bnhansn/ex_gdax
  * Coinbase API adapter: https://github.com/seymores/coinbase_ex
  * A local database server.

## Learn more

  * GDAX API docs: https://docs.gdax.com
  * Coinbase API docs: https://developers.coinbase.com/api/v2

## Disclaimer

Use this at your own risk. This project is unmaintained and subject to massive change at any time.
