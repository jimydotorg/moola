defmodule Moola.GDAXSocket do

  @moduledoc ~S"""
  ```
  Moola.GDAXSocket.start!
  ```
  """

  use WebSockex

  import Moola.Util
  alias Decimal, as: D
  alias Moola.Repo
  alias Moola.Ticker
  alias Moola.GDAXState

  def socket_url, do: Application.get_env(:moola, Moola.GDAXSocket)[:socket_url]
  def ticker_period, do: Application.get_env(:moola, Moola.GDAXSocket)[:ticker_period]
  def product_ids, do: Application.get_env(:moola, Moola.GDAXSocket)[:product_ids]
     
  def start_link() do
    init_state = %{
      timestamps: %{}, 
      volumes: %{},
      prices: %{},
      max_prices: %{},
      min_prices: %{},
      asks: %{},
      bids: %{},
      latency_log: DateTime.utc_now
    }

    D.set_context(%D.Context{D.get_context | precision: 2})

    case WebSockex.start_link(socket_url(), __MODULE__, init_state) do
      {:ok, pid} = result -> 
        pid |> Process.register(Moola.GDAXSocket) |> ZX.i("Start GDAXSocket")
        WebSockex.send_frame(pid, {:text, subscriptions()})
        result
      err -> err
    end
  end

  def subscriptions do
    %{
      type: "subscribe",
      product_ids: product_ids(),
      channels: ["heartbeat", 
                  %{name: "ticker", product_ids: product_ids()},
                  %{name: "matches", product_ids: product_ids()},
                  %{name: "level2", product_ids: product_ids()},
                ]
    }
    |> Poison.encode!
  end

  def start!() do
    case start_link() do
      {:ok, pid} -> pid
      _ -> nil
    end
  end

  def handle_connect(_conn, state) do
    IO.puts("Connected!")
    {:ok, state}
  end

  def handle_info({:ssl_closed, _} = msg, state) do
    ZX.i(msg, "handle_info")
    Process.exit(self(), :kill)
    {:ok, state}
  end

  def handle_disconnect(connection_status_map, state) do
    ZX.i(connection_status_map, "handle_disconnect")
    {:ok, state}
  end

  def handle_frame({_, msg}, state) do
    payload = msg |> Poison.decode!
    case process_payload(payload["type"], payload, state) do
      nil -> {:ok, state}
      new_state -> {:ok, new_state}
    end
  end
  
  def process_payload(type, msg, state) when type in ["match", "last_match"] do

    with symbol <- msg |> Map.get("product_id") |> symbolize,
      {:ok, now, _} <- msg |> Map.get("time") |> DateTime.from_iso8601,
      {:ok, price} <- msg |> Map.get("price") |> D.parse,
      {:ok, size} <-  msg |> Map.get("size") |> D.parse do

      GDAXState.put(symbol, %{price: price, match_time: now})      

      period = ticker_period()

      case elapsed_time(state, symbol, now) do
        nil -> 
          state
          |> update_prices(symbol, price)
          |> reset_time(symbol, now)
          |> reset_volume(symbol, size)

        elapsed when elapsed < period ->
          state
          |> update_prices(symbol, price)
          |> accumulate_volume(symbol, size)

        elapsed -> 
          # Calculate volume using floats, since doing it in Decimal API renders it unreadable:
          fvolume = volume(state, symbol) |> D.to_float
          fsize = size |> D.to_float
          fvolume = ticker_period() * (fvolume + fsize)/elapsed
          save_ticker(symbol, state, msg, D.new(fvolume))

          state
          |> update_prices(symbol, price)
          |> reset_prices
          |> reset_time(symbol, now)
          |> reset_volume(symbol)
      end
    else
      _ -> nil
    end
  end

  def process_payload("ticker", msg, state) do
    symbol = msg["product_id"] |> symbolize
    lowest_ask = msg["best_ask"] |> D.new 
    highest_bid = msg["best_bid"] |> D.new
    # Moola.GDAXState.put(symbol, %{lowest_ask: lowest_ask, highest_bid: highest_bid})      
    state
  end

  def process_payload("subscriptions", _, _), do: nil

  def process_payload("heartbeat", msg, state) do
    {:ok, now, _} = msg |> Map.get("time") |> DateTime.from_iso8601
    GDAXState.put(:time, %{now: now})

    # Log API latency every 30 seconds
    state = with last_log <- state.latency_log,
      elapsed <- DateTime.diff(DateTime.utc_now, last_log, :milliseconds) do
      cond do
        elapsed > 30000 -> 
          Task.start(fn -> Moola.GDAX.log_latency() end)
          %{state | latency_log: DateTime.utc_now}
        true -> 
          state
      end
    end   

    state
  end

  def process_payload("snapshot", msg, state) do
    symbol = msg["product_id"] |> symbolize
    asks = msg["asks"] |> book_array_to_map
    bids = msg["bids"] |> book_array_to_map

    all_asks = Map.get(state, :asks) |> Map.put(symbol, asks)
    all_bids = Map.get(state, :bids) |> Map.put(symbol, bids)

    %{state | asks: all_asks, bids: all_bids}
  end

  def process_payload("l2update", msg, state) do
    symbol = msg["product_id"] |> symbolize
    {:ok, now, _} = msg["time"] |> DateTime.from_iso8601

    state = msg["changes"]
    |> Enum.reduce(
        state, 
        fn([side, level, size], acc) -> 
          case side do
            "buy" -> update_bid(acc, symbol, level, size)
            "sell" -> update_ask(acc, symbol, level, size)
            wtf -> ZX.i("WTF? #{wtf}")
          end
        end)

    # Shitty hack:
    case :rand.uniform(50) do
      1 -> Moola.GDAXState.put(symbol, %{lowest_ask: lowest_ask(state, symbol), highest_bid: highest_bid(state, symbol), order_time: now})     
      _ -> nil
    end

    state
  end

  def process_payload(_, msg, state) do
    msg |> ZX.i("UNKNOWN PAYLOAD")
    state
  end

  defp elapsed_time(state, symbol, time) do
    timestamps = Map.get(state, :timestamps)
    case Map.get(timestamps, symbol) do
      nil -> nil
      ts -> DateTime.diff(time, ts, :milliseconds) / 1000.0
    end
  end

  defp reset_time(state, symbol, time) do
    timestamps = Map.get(state, :timestamps)
    timestamps = timestamps |> Map.put(symbol, time)
    %{state | timestamps: timestamps}
  end

  defp volume(state, symbol) do
    volumes = Map.get(state, :volumes)
    Map.get(volumes, symbol)
  end

  defp accumulate_volume(state, symbol, increment) do
    volumes = Map.get(state, :volumes)
    value = Map.get(volumes, symbol, D.new(0.0))
    volumes = volumes |> Map.put(symbol, D.add(value, D.new(increment)))
    %{state | volumes: volumes}
  end

  defp reset_volume(state, symbol, value \\ nil) do
    volumes = Map.get(state, :volumes)
    value = value || D.new(0.0)
    volumes = volumes |> Map.put(symbol, value)
    %{state | volumes: volumes}
  end

  defp save_ticker(symbol, state, message, volume) do
    attrs = %{
      volume: volume,
      usd_volume: usd_volume(state, symbol, volume),
      min_price: state |> Map.get(:min_prices) |> Map.get(symbol),
      max_price: state |> Map.get(:max_prices) |> Map.get(symbol)
    }

    result = %Ticker{}
    |> Ticker.changeset(attrs, message)
    |> Repo.insert

    # Broadcast to channels:
    with {:ok, tick} <- result do
      Moola.NotifyChannels.send_channel("ticker:gdax", "update", %{gdaxTicker: [tick]})
    end

    result
  end

  defp update_prices(state, symbol, price) do

    x_price = Map.get(state, :max_prices) |> Map.get(symbol, D.new(0))
    n_price = Map.get(state, :min_prices) |> Map.get(symbol, D.new(100000000))
    max_prices = Map.get(state, :max_prices) |> Map.put(symbol, D.max(price, x_price))
    min_prices = Map.get(state, :min_prices) |> Map.put(symbol, D.min(price, n_price))
    prices = Map.get(state, :prices) |> Map.put(symbol, price)
    %{state | prices: prices, min_prices: min_prices, max_prices: max_prices}
  end

  defp reset_prices(state) do
    prices = Map.get(state, :prices)
    %{state | min_prices: prices, max_prices: prices}
  end

  defp usd_volume(state, symbol, volume) do
    prices = Map.get(state, :prices)
    case symbol do
      :"eth-btc" -> 
        with btc_usd <- Map.get(prices, :"btc-usd"),
          eth_btc <- Map.get(prices, :"eth-btc") do
          volume |> D.mult(eth_btc) |> D.mult(btc_usd)
        end
      :"bch-btc" -> 
        with btc_usd <- Map.get(prices, :"btc-usd"),
          bch_btc <- Map.get(prices, :"bch-btc") do
          volume |> D.mult(bch_btc) |> D.mult(btc_usd)
        end
      _ -> 
        case Map.get(prices, symbol) do
          nil -> nil
          rate -> volume |> D.mult(rate)
        end
    end
  end

  defp book_array_to_map(array) do
    array |> Enum.reduce(%{}, 
      fn([price, size], acc) ->
        acc |> Map.put(book_key(price), book_size(size))
      end)
  end

  defp book_key(string_value) do
    {f_price, _} = Float.parse(string_value)
    round(f_price * 100)
  end

  defp value_for_key(key) do
    D.div(D.new(key), D.new(100))
  end

  defp book_size(string_value) do
    {:ok, d_size} = D.parse(string_value)
    d_size
  end

  defp update_bid(state, symbol, level, size) do
    my_bids = case size do
      "0" -> 
        state
        |> Map.get(:bids)
        |> Map.get(symbol)
        |> Map.delete(book_key(level))
      _ -> 
        state
        |> Map.get(:bids)
        |> Map.get(symbol)
        |> Map.put(book_key(level), book_size(size))
    end

    new_bids = state |> Map.get(:bids) |> Map.put(symbol, my_bids)
    %{state | bids: new_bids}
  end

  defp update_ask(state, symbol, level, size) do
    my_asks = case size do
      "0" -> 
        state
        |> Map.get(:asks)
        |> Map.get(symbol)
        |> Map.delete(book_key(level))
      _ ->     
        state
        |> Map.get(:asks)
        |> Map.get(symbol)
        |> Map.put(book_key(level), book_size(size))
    end

    new_asks = state |> Map.get(:asks) |> Map.put(symbol, my_asks)
    %{state | asks: new_asks}
  end

  defp highest_bid(state, symbol) do
    asks = state |> Map.get(:bids) |> Map.get(symbol |> symbolize)
    {level, size} = asks |> Enum.sort(fn({k1, v1}, {k2, v2}) -> k1 > k2 end) |> Enum.at(0)
    value_for_key(level)
  end

  defp lowest_ask(state, symbol) do
    asks = state |> Map.get(:asks) |> Map.get(symbol |> symbolize)
    {level, size} = asks |> Enum.sort(fn({k1, v1}, {k2, v2}) -> k1 < k2 end) |> Enum.at(0)
    value_for_key(level)
  end

end