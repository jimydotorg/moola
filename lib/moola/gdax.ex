defmodule Moola.GDAX do

  use Moola, :context
  alias Decimal, as: D
  alias Moola.GDAXState
  alias Moola.Fill
  alias Moola.Order
  alias Moola.FillQuery
  alias Moola.OrderQuery
  alias Moola.OrderLatency

  def balance(currency) do
    with {:ok, info} <- ExGdax.get_position,
      cur <- currency |> upcase,
      {balance, _} = info["accounts"][cur]["balance"] |> Float.parse 
    do
      balance
    end
  end

  def dollars_balance do
    balance("usd")
  end

  def dollars_purchased(symbol, age) do
    D.set_context(%D.Context{D.get_context | precision: 10})
    FillQuery.query_fills(side: "buy", symbol: symbol, now: current_time(), age: age)
    |> Enum.reduce(D.new(0), fn(fill, sum) -> sum |> D.add(D.mult(fill.size, fill.price)) end)
  end

  def dollars_sold(symbol, age) do
    D.set_context(%D.Context{D.get_context | precision: 10})
    FillQuery.query_fills(side: "sell", symbol: symbol, now: current_time(), age: age)
    |> Enum.reduce(D.new(0), fn(fill, sum) -> sum |> D.add(D.mult(fill.size, fill.price)) end)
  end

  def last_fill do
    D.set_context(%D.Context{D.get_context | precision: 10})
    FillQuery.query_fills(now: current_time(), limit: 1) |> Enum.at(0)
  end

  def last_fill(symbol) do
    D.set_context(%D.Context{D.get_context | precision: 10})
    FillQuery.query_fills(symbol: symbol, now: current_time(), limit: 1) |> Enum.at(0)
  end

  def unwind_last_fill(symbol) do
    with %Fill{} = fill <- last_fill(symbol) do
      case fill.side do
        "sell" -> 
          buy_quantity(symbol, fill.size)
        "buy" -> 
          sell_quantity(symbol, fill.size)
      end
    end
  end

  def last_order do
    D.set_context(%D.Context{D.get_context | precision: 10})
    OrderQuery.query_orders(now: current_time(), limit: 1) |> Enum.at(0)
  end

  def last_order(symbol) do
    D.set_context(%D.Context{D.get_context | precision: 10})
    OrderQuery.query_orders(symbol: symbol, now: current_time(), limit: 1) |> Enum.at(0)
  end

  def buy_fixed_dollars(symbol, dollar_amount, max_price \\ nil) do
    symbol = atomize(symbol)
    D.set_context(%D.Context{D.get_context | precision: 10})

    with info when is_map(info) <- GDAXState.get(symbol),
      now <- GDAXState.get(:time) |> Map.get(:now),
      spread <- D.sub(info.lowest_ask, info.highest_bid),
      true <- D.to_float(spread) < 2.0,
      max_price <- (max_price || 100000000) |> D.new,
      mid_price <- D.div(D.add(info.highest_bid, info.lowest_ask), D.new(2)),
      my_bid_price <- D.min(max_price, D.sub(mid_price, D.new(0.01))),
      size <- D.div(D.new(dollar_amount), my_bid_price),
      price_time <- info.order_time,
      elapsed <- DateTime.diff(now, price_time, :milliseconds) / 1000.0,
      true <- elapsed < 2,
      existing_order <- OrderQuery.query_orders(symbol: symbol, side: "buy", status: ["open", "pending"]) |> Enum.at(0) do

      cond do
        existing_order == nil -> 
          create_buy_order(symbol, my_bid_price, size)

        equal_prices?(existing_order.price, my_bid_price, :ceiling) && equal_sizes?(existing_order.size, size) ->
          {:ok, existing_order} 

        true -> 
          case cancel_order(existing_order) do
            {:ok, _} -> create_buy_order(symbol, my_bid_price, size)
            err -> err
          end
      end

    else
      err -> {:error, err} |> ZX.i
    end
  end

  def buy_quantity(symbol, quantity, max_price \\ nil) do
    symbol = atomize(symbol)
    D.set_context(%D.Context{D.get_context | precision: 10})

    with info when is_map(info) <- GDAXState.get(symbol),
      now <- GDAXState.get(:time) |> Map.get(:now),
      spread <- D.sub(info.lowest_ask, info.highest_bid),
      true <- D.to_float(spread) < 2.0,
      max_price <- (max_price || 100000000) |> D.new,
      mid_price <- D.div(D.add(info.highest_bid, info.lowest_ask), D.new(2)),
      my_bid_price <- D.min(max_price, D.sub(mid_price, D.new(0.01))),
      size <- quantity |> D.new,
      price_time <- info.order_time,
      elapsed <- DateTime.diff(now, price_time, :milliseconds) / 1000.0,
      true <- elapsed < 2,
      existing_order <- OrderQuery.query_orders(symbol: symbol, side: "buy", status: ["open", "pending"]) |> Enum.at(0) do

      cond do
        existing_order == nil -> 
          create_buy_order(symbol, my_bid_price, size)

        equal_prices?(existing_order.price, my_bid_price, :ceiling) && equal_sizes?(existing_order.size, size) ->
          {:ok, existing_order} 

        true -> 
          case cancel_order(existing_order) do
            {:ok, _} -> create_buy_order(symbol, my_bid_price, size)
            err -> err
          end
      end

    else
      err -> {:error, err} |> ZX.i
    end
  end

  def sell_fixed_dollars(symbol, dollar_amount, min_price \\ nil) do
    symbol = atomize(symbol)
    D.set_context(%D.Context{D.get_context | precision: 10})

    with info when is_map(info) <- GDAXState.get(symbol),
      now <- GDAXState.get(:time) |> Map.get(:now),
      spread <- D.sub(info.lowest_ask, info.highest_bid),
      true <- D.to_float(spread) < 2.0,
      min_price <- (min_price || 0) |> D.new,
      mid_price <- D.div(D.add(info.highest_bid, info.lowest_ask), D.new(2)),
      my_ask_price <- D.max(min_price, D.add(mid_price, D.new(0.01))),
      size <- D.div(D.new(dollar_amount), my_ask_price),
      price_time <- info.order_time, 
      elapsed <- DateTime.diff(now, price_time, :milliseconds) / 1000.0,
      true <- elapsed < 2,
      true <- D.to_float(size) <= balance(extract_currency(symbol)),
      existing_order <- OrderQuery.query_orders(symbol: symbol, side: "sell", status: ["open", "pending"]) |> Enum.at(0)

    do

      cond do
        existing_order == nil -> 
          create_sell_order(symbol, my_ask_price, size)

        equal_prices?(existing_order.price, my_ask_price, :floor) && equal_sizes?(existing_order.size, size) ->
          {:ok, existing_order} 

        true -> 
          case cancel_order(existing_order) do
            {:ok, _} -> create_sell_order(symbol, my_ask_price, size)
            err -> err
          end
      end

    else
      err -> {:error, err} |> ZX.i
    end
  end

  def sell_quantity(symbol, quantity, min_price \\ nil) do
    D.set_context(%D.Context{D.get_context | precision: 10})

    with info when is_map(info) <- GDAXState.get(symbol),
      now <- GDAXState.get(:time) |> Map.get(:now),
      spread <- D.sub(info.lowest_ask, info.highest_bid),
      true <- D.to_float(spread) < 10.0,
      min_price <- (min_price || 0) |> D.new,
      mid_price <- D.div(D.add(info.highest_bid, info.lowest_ask), D.new(2)),
      my_ask_price <- D.max(min_price, D.add(mid_price, D.new(0.01))),
      size <- quantity |> D.new,
      price_time <- info.order_time,
      elapsed <- DateTime.diff(now, price_time, :milliseconds) / 1000.0,
      true <- elapsed < 2,
      true <- D.to_float(size) <= balance(extract_currency(symbol)),
      existing_order <- OrderQuery.query_orders(symbol: symbol, side: "sell", status: ["open", "pending"]) |> Enum.at(0)

    do

      cond do
        existing_order == nil -> 
          create_sell_order(symbol, my_ask_price, size)

        equal_prices?(existing_order.price, my_ask_price, :floor) && equal_sizes?(existing_order.size, size) ->
          {:ok, existing_order} 

        true -> 
          case cancel_order(existing_order) do
            {:ok, _} -> create_sell_order(symbol, my_ask_price, size)
            err -> err
          end
      end

    else
      err -> {:error, err} |> ZX.i
    end
  end

  def create_buy_order(symbol, price, size), do: create_order(symbol, price, size, "buy")
  def create_sell_order(symbol, price, size), do: create_order(symbol, price, size, "sell")

  def create_order(symbol, price, size, side) do
    price_rounding = case side do
      "buy" -> :ceiling
      "sell" -> :floor
    end

    with {:ok, result} <-  %{
                              type: "limit",
                              side: side,
                              product_id: upcase(symbol),
                              price: format_usd_price(price, price_rounding),
                              size: format_order_size(size),
                              time_in_force: "GTT",
                              cancel_after: "hour",
                              post_only: true
                            }
                            |> ZX.i("order")
                            |> ExGdax.create_order
    do
      save_order_info(result) 
      |> ZX.i("result")
    else
      err -> ZX.i(err, "error")
    end
  end

  def cancel_order(%Order{} = order) do
    case ExGdax.cancel_order(order.gdax_id) do
      {:ok, _} -> Repo.delete(order)
      {:error, _, 400} -> Repo.delete(order)  # Order already done
      {:error, _, 404} -> Repo.delete(order)  # Order not found
      err -> err
    end
  end

  def cancel_last_order do
    with %Order{} <- last_order do
      cancel_order(last_order)
    end
  end

  def cancel_all_orders() do
    with {:ok, _} <- ExGdax.cancel_orders() do
      Repo.delete_all(Order)
    end
  end

  def retrieve_orders(symbol) do
    with {:ok, orders} <- ExGdax.list_orders(product_id: upcase(symbol)) do
      Repo.delete_all(Order)
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

  def retrieve_fills do
    with %Order{} = order <- last_order,
      symbol <- order.product_id 
    do
      retrieve_fills(symbol)
    end
  end

  @doc """
  Test the GDAX API latency by creating a crap order that will most likely not get filled and
  then immediately deleting it
  """
  def measure_latency do
    with symbol <- "btc-usd",
      dollar_amount <- 13.37,
      info when is_map(info) <- GDAXState.get(symbol),
      now <- GDAXState.get(:time) |> Map.get(:now),
      low_bid_price <- D.div(info.highest_bid, D.new(8)),
      size = D.div(D.new(dollar_amount), low_bid_price),
      price_time <- info.order_time,
      elapsed <- DateTime.diff(now, price_time, :milliseconds) / 1000.0,
      true <- elapsed < 2 do

      time1 = DateTime.utc_now

      params = %{
        type: "limit",
        side: "buy",
        product_id: upcase(symbol),
        price: format_usd_price(low_bid_price),
        size: format_order_size(size),
        time_in_force: "GTT",
        cancel_after: "hour",
        post_only: true
      }

      case ExGdax.create_order(params) do
        {:ok, %{"id" => id} = order} ->
          time2 = DateTime.utc_now
          case ExGdax.cancel_order(id) do
            {:ok, _} -> 
              time3 = DateTime.utc_now
              latency = DateTime.diff(time2, time1, :milliseconds) + DateTime.diff(time3, time2, :milliseconds)
              {:ok, latency}

            {:error, _, _} = err -> err
            _ -> {:error, "fail"} 
          end
        {:error, _, _} = err -> err
        _ -> {:error, "FAIL"}
      end
    end
  end

  def log_latency do
    with now <- DateTime.utc_now,
      {:ok, latency} <- measure_latency() do
      result = %OrderLatency{}
      |> OrderLatency.changeset(%{milliseconds: latency, timestamp: now})
      |> Repo.insert

      with {:ok, obj} <- result do
        Moola.NotifyChannels.send_channel("latency:gdax", "update", %{gdaxLatency: [obj]})
      end

      result
    end
  end

  def eth_usd_btc do
    with eth_info <- GDAXState.get("eth-usd"),
      btc_info <- GDAXState.get("btc-usd"),
      mid_price <- D.div(D.new(eth_info.price), D.new(btc_info.price)),
      low_price <- D.div(D.new(eth_info.highest_bid), D.new(btc_info.lowest_ask)),
      high_price <- D.div(D.new(eth_info.lowest_ask), D.new(btc_info.highest_bid)) do
      {low_price, mid_price, high_price}
    end
  end

  # Private functions

  defp current_time do
    case GDAXState.get(:time) do
      %{now: now} -> now
      _ -> DateTime.utc_now
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

  defp format_usd_price(number, rounding \\ :half_up) do
    D.set_context(%D.Context{D.get_context | precision: 10})
    D.new(number) |> D.round(2, rounding) |> D.to_string(:normal)
  end

  defp format_order_size(number) do
    D.set_context(%D.Context{D.get_context | precision: 4, rounding: :ceiling})
    D.new(number) |> D.reduce |> D.to_string(:normal)
  end

  defp equal_prices?(p1, p2, rounding \\ :half_up) do
    D.set_context(%D.Context{D.get_context | precision: 10})
    D.equal?(D.round(p1, 2, rounding), D.round(p2, 2, rounding))
  end

  defp equal_sizes?(s1, s2) do
    D.set_context(%D.Context{D.get_context | precision: 3, rounding: :ceiling})
    D.equal?(D.reduce(s1), D.reduce(s2))
  end

  defp extract_currency(symbol) do
    with sym <- symbol |> upcase,
      matches <- Regex.split(~r/-/, sym),
      "USD" <- Enum.at(matches, 1)
    do
      Enum.at(matches, 0)
    end
  end

end