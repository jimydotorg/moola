defmodule Moola.GDAXSocket do
  use WebSockex

  import Moola.Util
  alias Moola.Repo
  alias Moola.Ticker

  @product_ids ["ETH-USD", "BTC-USD", "LTC-USD", "ETH-BTC"]

  @moduledoc ~S"""
  ```
  Moola.GDAXSocket.start!
  ```
  """
     
  def subscriptions do
    subscription = %{
      type: "subscribe",
      product_ids: @product_ids,
      channels: ["heartbeat", %{name: "ticker", product_ids: @product_ids}]
    }
    |> Poison.encode!
  end

  def start(url) do

    init_state = %{
      timestamps: %{}, 
      volumes: %{}
    }

    case WebSockex.start(url, __MODULE__, init_state) do
      {:ok, pid} = result -> 
        WebSockex.send_frame(pid, {:text, subscriptions})
        result
      err -> err
    end
  end

  def start!(url \\ "wss://ws-feed.gdax.com/") do
    case start(url) do
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
  
  def process_payload("ticker", msg, state) do

    with symbol <- msg |> Map.get("product_id") |> symbolize,
      {:ok, now, _} <- msg |> Map.get("time") |> DateTime.from_iso8601,
      {size, _} <-  msg |> Map.get("last_size") |> Float.parse do

      case elapsed_time(state, symbol, now) do
        nil -> 
          state
          |> reset_time(symbol, now)
          |> reset_volume(symbol)

        elapsed when elapsed < 60 ->
          state
          |> accumulate_volume(symbol, size)

        elapsed -> 
          save_ticker(state, msg, 60.0*(volume(state, symbol) + size)/elapsed)
          state
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

  defp save_ticker(state, message, volume) do
    %Ticker{}
    |> Ticker.changeset(%{volume_60s: volume}, message)
    |> Repo.insert
  end
end