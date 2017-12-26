defmodule Moola.DollarSeller do

  use GenServer
  alias Decimal, as: D
  alias Moola.Fill
  alias Moola.Order
  alias Moola.FillQuery
  alias Moola.OrderQuery
  alias Moola.GDAX
  alias Moola.GDAXState

  def start_link(state \\ %{}), do: GenServer.start_link(__MODULE__, state)

  def start! do
    case start_link(%{manual_start: true}) do
      {:ok, pid} -> pid
      _ -> nil
    end
  end

  def get_config(key \\ nil, default \\ nil) do
    config = Application.get_env(:moola, Moola.DollarSeller)
    case key do
      nil -> config
      k -> 
        case Keyword.get(config, k) do
          nil -> default
          value -> value
        end
    end
  end

  def init(state) do
    cond do 
      true == get_config(:auto_start) -> 
        print_config()
        Process.send_after(self(), :work, 3500)
      true == state[:manual_start] -> 
        print_config()
        Process.send_after(self(), :work, 1)
      true -> 
        nil
    end

    {:ok, state}
  end

  def handle_info(:work, state) do
    pause_time = do_shit()
    Process.send_after(self(), :work, (round(pause_time) * 1000) + :rand.uniform(1337)) 
    {:noreply, state} 
  end

  defp do_shit do

    with balance when is_float(balance) <- GDAX.dollars_balance,
      true <- balance < get_config(:max_usd_balance, 0) do

      status = get_config(:sell_targets, [])
        |> Enum.reduce(
            :done, 
            fn({symbol, limit}, acc) ->

              with :ok <- GDAX.retrieve_orders(symbol),
                :ok <- GDAX.retrieve_fills(symbol) do

                  case dump_allowance(symbol, limit) do
                    {:done, _} -> acc
                    {:pending, _} -> :pending
                    _ -> :error                      
                  end
              else
                _ -> :error
              end
            end
          )

      pause_period(status)
    else
      _ -> pause_period(:done)
    end
  end

  defp sell_period, do: get_config(:sell_period_seconds, 3600)
  defp pause_period(status) do
    case status do
      :done -> sell_period/2.0
      :pending -> get_config(:rebid_seconds, 3) # <- when processing buy, readjust bid every X seconds
      :error -> 10 # <- error in API call or something else? try again shortly
    end
  end

  # Returns one of:
  # {:done, amount} - we've already sold this amount for current period
  # {:pending, amount} - order has been placed for amount
  # {:error, message} - something went wrong
  defp dump_allowance(symbol, limit) do
    case GDAX.dollars_sold(symbol, sell_period()) |> D.to_float do
      amount when amount >= limit -> 
        {:done, amount}

      amount when amount < limit -> 
        sell_amount = limit - amount
        case GDAX.sell_fixed_dollars(symbol, sell_amount) do
          {:ok, order} -> {:pending, sell_amount}
          err -> err
        end
    end
  end

  defp print_config do
    get_config() |> ZX.i("Auto-sell settings:")
  end

end