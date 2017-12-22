defmodule Moola.GDAX do

  use Moola, :context
  alias Decimal, as: D
  alias Moola.GDAXState
  alias Moola.Fill
  alias Moola.Order
  alias Moola.FillQuery
  alias Moola.OrderQuery

  def dollars_balance do
    with {:ok, info} <- ExGdax.get_position,
      {balance, _} = info["accounts"]["USD"]["balance"] |> Float.parse do
      balance
    end
  end

  def dollars_purchased(symbol, age) do
    D.set_context(%D.Context{D.get_context | precision: 10})
    gdax_time = case GDAXState.get(:time) do
      %{now: now} -> now
      _ -> DateTime.utc_now
    end
    FillQuery.query_fills(symbol: symbol, now: gdax_time, age: age)
    |> Enum.reduce(D.new(0), fn(fill, sum) -> sum |> D.add(D.mult(fill.size, fill.price)) end)
  end

  def buy_fixed_dollars(symbol, dollar_amount) do
    with info when is_map(info) <- GDAXState.get(symbol),
      now <- GDAXState.get(:time) |> Map.get(:now),
      ticker_price <- info.price,
      price <- D.min(info.highest_bid, info.lowest_ask),
      price_time <- info.time,
      elapsed <- DateTime.diff(now, price_time, :milliseconds) / 1000.0,
      true <- elapsed < 5 do
        my_bid_price = D.sub(price, D.new(0.01))
        size = D.div(D.new(dollar_amount), my_bid_price)

        ZX.i({ticker_price, my_bid_price, info.highest_bid, info.lowest_ask}, symbol)
        create_buy_order(symbol, my_bid_price, size)

    else
      _ -> {:error, "Been a while since the last transaction. Is GDAXSocket running?"} |> ZX.i
    end
  end

  def create_buy_order(symbol, price, size) do
    d_price = format_usd_price(price)
    d_size = format_order_size(size)
    {d_price, d_size} |> ZX.i("buy #{symbol}")

    with {:ok, result} <-  %{
                              type: "limit",
                              side: "buy",
                              product_id: upcase(symbol),
                              price: d_price,
                              size: d_size,
                              time_in_force: "GTT",
                              cancel_after: "hour",
                              post_only: true
                            }
                            |> ExGdax.create_order do
      save_order_info(result)
    end
  end

  defp format_usd_price(number) do
    D.set_context(%D.Context{D.get_context | precision: 10})
    D.new(number) |> D.round(2) |> D.to_string(:normal)
  end

  defp format_order_size(number) do
    D.set_context(%D.Context{D.get_context | precision: 4, rounding: :ceiling})
    D.new(number) |> D.reduce |> D.to_string(:normal)
  end

  def cancel_order(%Order{} = order) do
    with {:ok, _} <- ExGdax.cancel_order(order.gdax_id) do
      Repo.delete(order)
    end
  end

  def cancel_all_orders() do
    with {:ok, _} <- ExGdax.cancel_orders() do
      Repo.delete_all(Order)
    end
  end

  def retrieve_orders(symbol) do
    with {:ok, orders} <- ExGdax.list_orders(product_id: upcase(symbol)) do
      orders
      |> Enum.each(fn(x) -> save_order_info(x) end)
    else
      _ -> :error
    end
  end

  def retrieve_fills(symbol) do
    with {:ok, fills} <- ExGdax.list_fills(product_id: upcase(symbol)) do
      fills
      |> Enum.each(fn(x) -> save_fill_info(x) end)
    else
      _ -> :error
    end
  end

  defp save_order_info(%{"id" => gdax_id} = info) do
    case Repo.get_by(Order, gdax_id: gdax_id) do
      %Order{} = order -> 
        order
        |> Order.changeset(info |> Map.delete("created_at"))
        |> Repo.update
      nil -> 
        %Order{}
        |> Order.changeset(info)
        |> Repo.insert
    end
  end

  defp save_fill_info(%{"trade_id" => trade_id} = info) do
    case Repo.get_by(Fill, trade_id: trade_id) do
      %Fill{} = fill -> 
        fill
        |> Fill.changeset(info |> Map.delete("created_at"))
        |> Repo.update
      nil -> 
        %Fill{} 
        |> Fill.changeset(info) 
        |> Repo.insert
    end
  end

end