defmodule Moola.Event do
  use Moola, :schema

  alias Moola.Event
  alias Moola.EventType
  alias Moola.ClientToken

  schema "log_events" do
    field :inserted_at, :utc_datetime
    field :info, :map

    belongs_to :client_token, ClientToken
    belongs_to :log_event_type, EventType
  end

  @doc false
  def changeset(%Event{} = event, attrs) do
    event
    |> cast(attrs, [:log_event_type_id, :inserted_at, :client_token_id, :info])
    |> put_change(:inserted_at, DateTime.utc_now)
    |> validate_required([:log_event_type_id, :inserted_at])
  end
end

defimpl Poison.Encoder, for: Moola.Event do
  use Moola, :encoder
  alias Moola.Event

  def encode(%Event{} = event, options \\ []) do
    %{
      id: Event.hashid(event),
      timestamp: event.inserted_at,
      type: Event.get_assoc(event, :log_event_type),
      info: event.info,
      client: event.client_token
    }
    |> Poison.Encoder.encode(options)

  end
end