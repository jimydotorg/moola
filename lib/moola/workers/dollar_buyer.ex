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

  # @period_targets ["eth-usd": 8.0, "btc-usd": 2.00, "bch-usd": 1.00, "ltc-usd": 0.0]
  @period_targets ["eth-usd": 50.0, "btc-usd": 100.00, "bch-usd": 25.00, "ltc-usd": 0.00]
  @period_duration_seconds 360
  @min_usd_balance 100.00

  @one_hour 3600
  @one_minute 60
  @check_period 18

  def start_link, do: GenServer.start_link(__MODULE__, %{})

  def start! do
    case start_link() do
      {:ok, pid} -> pid
      _ -> nil
    end
  end

  def init(state) do
    Process.send_after(self(), :work, 1 * 1000)
    {:ok, state}
  end

  def handle_info(:work, state) do
    pause_time = do_shit()
    Process.send_after(self(), :work, pause_time * 1000) 
    {:noreply, state}
  end

  defp do_shit do
    with balance when is_float(balance) <- GDAX.dollars_balance,
      true <- balance > @min_usd_balance do

      {status, message} = @period_targets 
        |> Enum.reduce(
            {:ok, "ok"},  
            fn({symbol, limit}, acc) -> 
              with :ok <- GDAX.retrieve_orders(symbol),
                :ok <- GDAX.retrieve_fills(symbol) do
                  case spend_allowance(symbol, limit) do
                    {:ok, _} -> acc
                    {:error, _} = err -> err
                    {:error, msg, _} -> {:error, msg} # <- ExGdax returns {:error, message, code} upon error
                  end
              else
                _ -> {:error, "error retrieving orders/fills"}
              end
            end
          )

      cond do
        status == :error -> 5 * @one_minute |> ZX.i("ERROR: #{message}")
        true -> @check_period
      end
    else
      _ -> @one_hour
    end
  end

  defp spend_allowance(symbol, limit) do
    case GDAX.dollars_purchased(symbol, @period_duration_seconds) |> D.to_float do
      amount when amount >= limit -> 
        {:ok, "purchased $#{amount}. goal achieved"}

      amount when amount < limit -> 
        # Do we have an outstanding order?
        case OrderQuery.query_orders(symbol: symbol, age: @period_duration_seconds, status: "open") |> Enum.at(0) do
          nil -> # no open orders
            GDAX.buy_fixed_dollars(symbol, limit - amount)

          %Order{} = order -> # cancel order before creating another one
            case GDAX.cancel_order(order) do
              {:ok, _} -> GDAX.buy_fixed_dollars(symbol, limit - amount)
              _ -> {:error, "unable to cancel previous order"}
            end
        end
    end
  end

end