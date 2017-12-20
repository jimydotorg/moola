defmodule Moola.Log do
  @moduledoc """
  General log service.
  """

  use Moola, :context
  import Moola.LogQuery

  alias Moola.Event
  alias Moola.EventType

  @separator "/"

  def record(%Moola.ClientToken{} = client, name, info) do
    with %EventType{} = type <- event_type_for(name) do
      %Event{} |> Event.changeset(%{log_event_type_id: type.id, client_token_id: client.id, info: info}) |> Repo.insert
    end
    client
  end

  def record(%Moola.ClientToken{} = client, name), do: record(client, name, nil)

  def record(%Plug.Conn{} = conn, name, info) do 
    record(conn.assigns[:client_token], name, info)
    conn
  end

  def record(%Phoenix.Socket{} = socket, name, info) do
    record(socket.assigns[:client_token], name, info)
    socket
  end

  def record(nil, name, info) do
    with %EventType{} = type <- event_type_for(name) do
      %Event{} |> Event.changeset(%{log_event_type_id: type.id, info: info}) |> Repo.insert
    end
  end

  def record(%Plug.Conn{} = conn, name), do: record(conn, name, nil)
  def record(%Phoenix.Socket{} = socket, name), do: record(socket, name, nil)

  def record(name, info) do
    with %EventType{} = type <- event_type_for(name) do
      %Event{} |> Event.changeset(%{log_event_type_id: type.id, info: info}) |> Repo.insert
    end
  end

  def record(name), do: record(name, nil)
  
  def error(type, name, info) do
    record("error/" <> name, info)
    case type do
      :serious -> 
        # TBD: send alert too
        nil
    end
  end

  def error(type, name), do: record(type, name, nil)
  def error(name), do: record(:warning, name, nil)

  defp event_type_for([], %EventType{} = type), do: type

  defp event_type_for([head | tail], %EventType{} = parent) do
    case Repo.get_by(EventType, name: head, parent_id: parent.id) do
      nil ->
        full_name = parent.full_name <> @separator  <> head
        case %EventType{} 
          |> EventType.changeset(%{name: head, parent_id: parent.id, full_name: full_name}) 
          |> Repo.insert do
            {:ok, new_type} -> event_type_for(tail, new_type)
          _ -> nil
        end
      type -> 
        event_type_for(tail, type)      
    end
  end

  # Root event type:
  defp event_type_for([head | tail]) do
    case Repo.one(from e in EventType, where: e.name == ^head, where: is_nil(e.parent_id)) do
      nil ->
        case %EventType{} 
          |> EventType.changeset(%{name: head, full_name: head}) 
          |> Repo.insert do
            {:ok, new_type} -> event_type_for(tail, new_type)
          _ -> nil
        end
      type -> 
        event_type_for(tail, type)
    end
  end

  defp event_type_for(full_name) do
    name = String.downcase(full_name)
    case Repo.get_by(EventType, full_name: name) do
      nil ->
        name 
        |> String.downcase
        |> String.split(@separator)
        |> Enum.filter(fn(x) -> x != "" end) # Filter out empty names. ("a//b" should be same as "a/b")
        |> event_type_for
      type ->
        type
    end
  end

end
