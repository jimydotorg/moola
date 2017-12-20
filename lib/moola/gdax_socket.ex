defmodule Moola.GDAXSocket do
  use WebSockex

  import Moola.Util
  alias Moola.Repo
  alias Moola.Ticker

  @product_ids ["ETH-USD", "BTC-USD", "LTC-USD", "ETH-BTC", "BCH-USD", "BCH-BTC"]
  @gdax_socket "wss://ws-feed.gdax.com/"
  @ticker_period 15.0

  @moduledoc ~S"""
  ```
  Moola.GDAXSocket.start!
  ```
  """
     
  def start_link(url \\ @gdax_socket) do
    init_state = %{
      timestamps: %{}, 
      volumes: %{},
      prices: %{},
      max_prices: %{},
      min_prices: %{}
    }

    case WebSockex.start(url, __MODULE__, init_state) do
      {:ok, pid} = result -> 
        pid |> Process.register(Moola.GDAXSocket)
        Moola.GDAXState.start_link
        WebSockex.send_frame(pid, {:text, subscriptions})
        result
      err -> err
    end
  end

  def subscriptions do
    subscription = %{
      type: "subscribe",
      product_ids: @product_ids,
      channels: ["heartbeat", 
                  %{name: "matches", product_ids: @product_ids}
                ]
    }
    |> Poison.encode!
  end

  def start!(url \\ @gdax_socket) do
    case start_link(url) do
      {:ok, pid} -> pid
      _ -> nil
    end
  end

  def terminate(reason, state) do
    exit(:normal)
  end

  def handle_connect(_conn, state) do
    IO.puts("Connected!")
    {:ok, state}
  end

  def handle_frame({type, msg}, state) do
    payload = msg |> Poison.decode!
    case process_payload(payload["type"], payload, state) do
      nil -> {:ok, state}
      new_state -> {:ok, new_state}
    end
  end
  
  def process_payload(type, msg, state) when type in ["match", "last_match"] do

    with symbol <- msg |> Map.get("product_id") |> symbolize,
      {:ok, now, _} <- msg |> Map.get("time") |> DateTime.from_iso8601,
      {price, _} <- msg |> Map.get("price") |> Float.parse,
      {size, _} <-  msg |> Map.get("size") |> Float.parse do

      Moola.GDAXState.put(symbol, %{price: price})
      
      case elapsed_time(state, symbol, now) do
        nil -> 
          state
          |> ZX.i(symbol)
          |> update_prices(symbol, price)
          |> reset_time(symbol, now)
          |> reset_volume(symbol, size)

        elapsed when elapsed < @ticker_period ->
          state
          |> update_prices(symbol, price)
          |> accumulate_volume(symbol, size)

        elapsed -> 
          save_ticker(symbol, state, msg, @ticker_period * (volume(state, symbol) + size)/elapsed)
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

    with symbol <- msg |> Map.get("product_id") |> symbolize,
      {:ok, now, _} <- msg |> Map.get("time") |> DateTime.from_iso8601,
      {price, _} <- msg |> Map.get("price") |> Float.parse,
      {size, _} <-  msg |> Map.get("last_size") |> Float.parse do

      case elapsed_time(state, symbol, now) do
        nil -> 
          state
          |> update_prices(symbol, price)
          |> reset_time(symbol, now)
          |> reset_volume(symbol)

        elapsed when elapsed < @ticker_period ->
          state
          |> update_prices(symbol, price)
          |> accumulate_volume(symbol, size)

        elapsed -> 
          save_ticker(symbol, state, msg, @ticker_period * (volume(state, symbol) + size)/elapsed)
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

  def process_payload("heartbeat", msg, state) do
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
      ts -> DateTime.diff(time, ts)
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
    value = Map.get(volumes, symbol, 0.0)
    volumes = volumes |> Map.put(symbol, value + increment)
    %{state | volumes: volumes}
  end

  defp reset_volume(state, symbol, value \\ 0.0) do
    volumes = Map.get(state, :volumes)
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

    %Ticker{}
    |> Ticker.changeset(attrs, message)
    |> Repo.insert
  end

  defp update_prices(state, symbol, price) do
    x_price = Map.get(state, :max_prices) |> Map.get(symbol, 0)
    n_price = Map.get(state, :min_prices) |> Map.get(symbol, 100000000)
    max_prices =  Map.get(state, :max_prices) |> Map.put(symbol, max(price, x_price))
    min_prices =  Map.get(state, :min_prices) |> Map.put(symbol, min(price, n_price))
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
        with btc_usd when is_float(btc_usd) <- Map.get(prices, :"btc-usd"),
          eth_btc when is_float(eth_btc) <- Map.get(prices, :"eth-btc") do
          volume * eth_btc * btc_usd
        end
      :"bch-btc" -> 
        with btc_usd when is_float(btc_usd) <- Map.get(prices, :"btc-usd"),
          bch_btc when is_float(bch_btc) <- Map.get(prices, :"bch-btc") do
          volume * bch_btc * btc_usd
        end
      _ -> 
        case Map.get(prices, symbol) do
          nil -> nil
          rate -> volume * rate
        end
    end
  end
end