# Moola

Manage your crypto Moola on Coinbase/GDAX.

## How to

    iex -S mix

## Setting your API Keys

Set your API keys as shell env variables or in `config/*.secret.exs` files.

## Dollar Cost Buying

DollarBuyer lets you buy a fixed dollar amount over a specified time period. The DollarBuyer can automatically run upon startup, or be started manually:

    Moola.DollarBuyer.start!

Set the buy parameters in `config/*.secret.exs`

    config :moola, Moola.DollarBuyer,
      auto_start: false,
      buy_targets: ["eth-usd": 25.0, "btc-usd": 25.0, "bch-usd": 13.37],
      buy_period_seconds: 300,
      min_usd_balance: 100.00

In the example above, the DollarBuyer will attempt to purchase $25 USD of ETH, $25 of BTC, and $13.37 of BCH every 300 seconds (5 minutes). It will do so only if there is at least $100 in your GDAX account.

## GDAXSocket and GDAXState

Moola.GDAXSocket listens to the GDAX websocket feed to provide real-time updates. Data points are logged every 15 seconds to the local database. Real-time updates are written to GDAXState, which provides quotes to the DollarBuyer.

## Notes

Numbers are often handled as Decimals (sometimes aliased as "D"), which results in greater accuracy, but worse code readability. See: https://hexdocs.pm/decimal/readme.html

Bids for fixed dollar buy orders are based on the current order book, and is somewhat convoluted. Read the code for Moola.GDAX.buy_fixed_dollars yourself. It is the result of a bunch of trial and error, and by no means optimal or even good.

One very important thing to keep in mind is that your bid should be based on the most current info available. If your price data is even a few seconds out of date, you will run into problems. This is why buy_fixed_dollars checks the timestamp on the price quote before placing an order.

"ZX.i" is my stupid function for printing debug statements, and is littered everywhere in the code. It's quicker than typing "IO.inspect"

## Known issues

If the websocket connection to GDAX dies, GDAXSocket does not automatically restart.

Autobuys works only when buying USD, so it can't be used for ETH-BTC. This is due mainly to the precision/formatting of bid prices, so that needs to be changed in order to support ETH-BTC exchange.

There is a bunch of unused code to support non-yet-existent frontend clients. (User, ClientToken, UserToken, etc) Probably best to ignore it.

## Unknown issues

Unknown, but there are probably many.

## Dependencies

  * GDAX API adapter: https://github.com/bnhansn/ex_gdax
  * Coinbase API adapter: https://github.com/seymores/coinbase_ex
  * A local database server.

## Disclaimer

Use this at your own risk. This project is unmaintained and subject to massive change at any time.

## Learn more

  * GDAX API docs: https://docs.gdax.com
