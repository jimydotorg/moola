defmodule Moola.OrderQuery do

  @default_limit 100

  use Moola, :context
  alias Moola.Order

  def order_query(options), do: (from item in Order) |> order_query(options)

  def order_query(query, options) do

    query = case options[:symbol] do
      nil -> query
      name ->
        with lname <- downcase(name) do
          from item in query, where: item.symbol == ^lname
        end
    end

    query = case options[:settled] do
      true -> from item in query, where: item.settled == true
      _ -> query
    end

    query = case options[:status] do
      nil -> query
      status -> from item in query, where: item.status == ^status
    end

    now = case options[:now] do
      nil -> DateTime.utc_now
      time -> time
    end

    query = case options[:age] do
      age when is_integer(age) -> 
        max_created_at = (DateTime.to_unix(now) - age) |> DateTime.from_unix!
        from item in query, where: item.created_at > ^max_created_at
      _ -> query
    end

    query
  end

  def query_orders(options), do: options |> order_query |> order_order(options) |> limit_query(options) |> Repo.all

  def order_order(query, options) do
    from item in query, order_by: [desc: item.created_at]
  end

  def limit_query(query, options) do
    case options[:limit] do
      lim when is_integer(lim) -> from item in query, limit: ^lim
      _ -> from item in query, limit: @default_limit
    end
  end

end
