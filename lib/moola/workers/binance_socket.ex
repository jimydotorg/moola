defmodule Moola.BinanceSocket do

  use WebSockex

  import Moola.Util
  alias Decimal, as: D
  alias Moola.Repo
  alias Moola.BinanceTicker
  alias Moola.BinanceState

  def socket_url, do: Application.get_env(:moola, Moola.BinanceSocket)[:socket_url]
  def ticker_period, do: Application.get_env(:moola, Moola.BinanceSocket)[:ticker_period]
  def product_ids, do: Application.get_env(:moola, Moola.BinanceSocket)[:product_ids]
     
  def stream_url do
    streams = product_ids 
    |> Enum.map(fn(x) -> String.downcase(x) end)
    |> Enum.reduce("", fn(x, acc) -> "#{x}@aggTrade/#{acc}" end) 
    |> String.trim_trailing("/")

    "#{socket_url}/stream?streams=#{streams}"
    |> ZX.i
  end

  def start_link do
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

    case WebSockex.start_link(stream_url(), __MODULE__, init_state) do
      {:ok, pid} = result -> 
        pid |> Process.register(Moola.BinanceSocket) |> ZX.i("Start BinanceSocket")
        result
      err -> err
    end
  end

  def start!() do
    case start_link() do
      {:ok, pid} -> pid
      _ -> nil
    end
  end

  def handle_connect(_conn, state) do
    IO.puts("Connected to Binance socket!")
    {:ok, state}
  end

  def handle_info({:ssl_closed, _} = msg, state) do
    Process.exit(self(), :kill)
    {:ok, state}
  end

  def handle_disconnect(connection_status_map, state) do
    ZX.i(connection_status_map, "handle_disconnect")
    {:ok, state}
  end

  def handle_frame({_, msg}, state) do
    payload = msg |> Poison.decode!
    case process_payload(payload, state) do
      nil -> {:ok, state}
      new_state -> {:ok, new_state}
    end
  end
  
  def process_payload(%{"data" => data, "stream" => stream}, state) do 
    cond do
      String.match?(stream, ~r/aggTrade/) -> process_data(data, "aggTrade", state)
      true -> {:ok, state}
    end
  end

  def process_data(data, "aggTrade", state) do 

    with symbol <- data |> Map.get("s") |> symbolize,
      {:ok, now} <- data |> Map.get("T") |> DateTime.from_unix(:millisecond),
      {:ok, price} <- data |> Map.get("p") |> D.parse,
      {:ok, size} <-  data |> Map.get("q") |> D.parse do

      BinanceState.put(symbol, %{price: price, match_time: now})

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
          save_ticker(symbol, state, data, D.new(fvolume))

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
    attrs = case priced_volumes(state, symbol, volume) do
      {:ok, btc_volume, usd_volume} -> 
        %{
          volume: volume,
          usd_volume: usd_volume,
          btc_volume: btc_volume,
          min_price: state |> Map.get(:min_prices) |> Map.get(symbol),
          max_price: state |> Map.get(:max_prices) |> Map.get(symbol)
        }
      _ -> 
        %{
          volume: volume,
          min_price: state |> Map.get(:min_prices) |> Map.get(symbol),
          max_price: state |> Map.get(:max_prices) |> Map.get(symbol)
        }
    end

    result = %BinanceTicker{}
    |> BinanceTicker.changeset(attrs, message)
    |> ZX.i("tick!")
    |> Repo.insert

    # Broadcast to channels:
    with {:ok, tick} <- result do
      Moola.NotifyChannels.send_channel("ticker:binance", "update", %{binanceTicker: [tick]})
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

  defp priced_volumes(state, symbol, volume) do
    string_symbol = symbol |> Atom.to_string
    
    with true <- String.match?(string_symbol, ~r/[a-z]{1,5}BTC$/i),
      prices <- Map.get(state, :prices),
      symbol_price <- Map.get(prices, symbol),
      btc_price <- Map.get(prices, "BTCUSDT" |> symbolize),
      btc_volume <- D.mult(symbol_price, volume),
      usd_volume <- D.mult(btc_volume, btc_price)
    do
      {:ok, btc_volume, usd_volume}
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