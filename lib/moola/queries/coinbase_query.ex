defmodule Moola.CoinbaseQuery do

  @default_limit 500

  use Moola, :context
  alias Moola.CoinbaseTicker
  alias Moola.OrderLatency

  def ticker_query(options), do: (from item in CoinbaseTicker) |> ticker_query(options)

  def ticker_query(query, options) do

    query = case options[:symbol] do
      nil -> query
      name ->
        with lname <- downcase(name) do
          from item in query, where: item.symbol == ^lname
        end
    end

    now = case options[:now] do
      nil -> DateTime.utc_now
      time -> time
    end

    query = case options[:age] do
      age when is_integer(age) -> 
        max_created_at = (DateTime.to_unix(now) - age) |> DateTime.from_unix!
        from item in query, where: item.timestamp > ^max_created_at
      _ -> query
    end

    query
  end

  def query_ticks(options), do: options |> ticker_query |> ticker_order(options) |> limit_query(options) |> Repo.all

  def ticker_order(query, options) do
    from item in query, order_by: [desc: item.timestamp]
  end

  def limit_query(query, options) do
    case options[:limit] do
      lim when is_integer(lim) -> from item in query, limit: ^lim
      _ -> from item in query, limit: @default_limit
    end
  end

end
