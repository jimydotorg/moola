defmodule Moola.DollarBuyer do

  @moduledoc ~S"""
  ```
  Moola.DollarBuyer.start!
  ```
  """

  use GenServer
  alias Decimal, as: D
  alias Moola.Fill
  alias Moola.Order
  alias Moola.FillQuery
  alias Moola.OrderQuery
  alias Moola.GDAX
  alias Moola.GDAXState

  @one_minute 60
  @one_hour 3600
  @one_day 3600*24

  def start_link, do: GenServer.start_link(__MODULE__, %{})

  def start! do
    case start_link() do
      {:ok, pid} -> pid
      _ -> nil
    end
  end

  def init(state) do
    Process.send_after(self(), :work, 3500)
    {:ok, state}
  end

  def handle_info(:work, state) do
    pause_time = case Application.get_env(:moola, Moola.DollarBuyer)[:enabled] do
      true -> do_shit()
      _ -> @one_day
    end
    Process.send_after(self(), :work, (pause_time * 1000) + :rand.uniform(2000)) 
    {:noreply, state}
  end

  defp do_shit do

    ZX.i("------------------------------------------------------------------------------------------------------------")

    with balance when is_float(balance) <- GDAX.dollars_balance,
      true <- balance > Application.get_env(:moola, Moola.DollarBuyer)[:min_usd_balance] do

      {status, message} = Application.get_env(:moola, Moola.DollarBuyer)[:buy_targets]
        |> Enum.reduce(
            {:ok, "ok"},  
            fn({symbol, limit}, acc) ->

              with :ok <- GDAX.retrieve_orders(symbol),
                :ok <- GDAX.retrieve_fills(symbol) do

                  print_current_values(symbol)
                  GDAXState.get(symbol) |> ZX.i(symbol)

                  case spend_allowance(symbol, limit) do
                    {:ok, _} -> acc
                    {:error, _} = err -> err
                    {:error, msg, _} -> {:error, msg} # <- ExGdax returns {:error, message, code} upon error
                  end
              else
                _ -> {:error, "error retrieving orders/fills"} |> ZX.i
              end
            end
          )

      cond do
        status == :error -> pause_period() |> ZX.i("ERROR: #{message}")
        true -> pause_period()
      end
    else
      _ -> @one_hour
    end
  end

  defp buy_period, do: Application.get_env(:moola, Moola.DollarBuyer)[:buy_period_seconds] || 3600
  defp pause_period, do: 15

  defp spend_allowance(symbol, limit) do
    case GDAX.dollars_purchased(symbol, buy_period()) |> D.to_float do
      amount when amount >= limit -> 
        {:ok, "purchased $#{amount} #{symbol}. goal achieved"}

      amount when amount < limit -> 
        # Do we have an outstanding order?
        case OrderQuery.query_orders(symbol: symbol, age: buy_period(), status: "open") |> Enum.at(0) do
          nil -> # no open orders
            GDAX.buy_fixed_dollars(symbol, limit - amount)

          %Order{} = order -> # cancel order before creating another one
            case GDAX.cancel_order(order) do
              {:ok, _} -> GDAX.buy_fixed_dollars(symbol, limit - amount)
              _ -> 
                GDAX.cancel_all_orders()
                {:error, "unable to cancel previous order"}
            end
        end
    end
  end

  defp print_current_values(symbol) do
    with info when is_map(info) <- GDAXState.get(symbol),
      now <- GDAXState.get(:time),
      ticker_price <- info.price,
      purchased <- GDAX.dollars_purchased(symbol, buy_period()),
      high_bid <- info.highest_bid,
      low_ask <- info.lowest_ask do
        ZX.i(%{price: ticker_price, purchased: purchased, servertime: now, localtime: DateTime.utc_now}, symbol)
    end
  end
end