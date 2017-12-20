defmodule Moola.LogQuery do

  @default_limit 100

  use Moola, :context
  alias Moola.Event
  alias Moola.EventType

  def event_query(options), do: (from item in Event) |> event_query(options)

  def event_query(query, options) do
    query = case options[:type] do
      nil -> 
        query

      %EventType{} = type -> 
        from item in query, where: [log_event_type_id: ^type.id]

      name when is_bitstring(name) ->
        with lname <- String.downcase(name) do
          from item in Event, join: t in EventType, where: t.full_name == ^lname, where: item.log_event_type_id == t.id
        end

      _ -> from item in Event, where: true == false # invalid type, so always return nothing.
    end
    query
  end

  def query_events(options), do: options |> event_query |> event_order(options) |> limit_query(options) |> Repo.all

  def event_order(query, options) do
    from item in query, order_by: [desc: item.inserted_at]
  end

  def limit_query(query, options) do
    case options[:limit] do
      lim when is_integer(lim) -> from item in query, limit: ^lim
      _ -> from item in query, limit: @default_limit
    end
  end

end
