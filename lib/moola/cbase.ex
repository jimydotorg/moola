defmodule Moola.CBase do

  use Moola, :context
  alias Decimal, as: D
  alias Moola.CBase
  alias Moola.CoinbaseTicker

  def retrieve_quote(symbol) do
    with %{"data" => %{"iso" => cb_time}} <- Coinbase.current_time(),
      {:ok, time, _} <- DateTime.from_iso8601(cb_time),
      {:ok, buy_price, buy_latency} <- retrieve_price(symbol, :buy),
      {:ok, sell_price, sell_latency} <- retrieve_price(symbol, :sell),
      {:ok, spot_price, spot_latency} <- retrieve_price(symbol, :spot) do

      total_latency = buy_latency + sell_latency + spot_latency

      %CoinbaseTicker{}
      |> CoinbaseTicker.changeset(%{symbol: symbol |> symbolize,
                                    buy_price: buy_price, 
                                    sell_price: sell_price, 
                                    spot_price: spot_price,
                                    latency: total_latency,
                                    timestamp: time,
                                    hour: time.hour,
                                    minute: time.minute,
                                    day_of_week: Date.day_of_week(time)
                                  })
      |> Repo.insert
    end     
  end

  defp retrieve_price(symbol, type) do
    t0 = DateTime.utc_now
    result = case type |> atomize do
      :buy -> Coinbase.get_buy_price(symbol) 
      :sell -> Coinbase.get_sell_price(symbol) 
      :spot -> Coinbase.get_spot_price(symbol) 
    end
    latency = DateTime.diff(DateTime.utc_now, t0, :milliseconds)

    case result do
      %{"data" => %{"amount" => amount}} -> {:ok, amount, latency}
      _ -> {:error, "failed to retrieve quote"}
    end
  end

end