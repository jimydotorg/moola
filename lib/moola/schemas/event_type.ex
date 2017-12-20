defmodule Moola.EventType do
  use Moola, :schema
  alias Moola.EventType

  schema "log_event_types" do
    field :description, :string
    field :name, :string
    field :full_name, :string
    field :parent_id, :id

    has_many :events, Moola.Event, foreign_key: :log_event_type_id

    timestamps()
  end

  @doc false
  def changeset(%EventType{} = event_type, attrs) do
    event_type
    |> cast(attrs, [:name, :full_name, :description, :parent_id])
    |> update_change(:name, &String.downcase/1)
    |> update_change(:full_name, &String.downcase/1)
    |> validate_required([:name, :full_name])
  end
end

defimpl Poison.Encoder, for: Moola.EventType do
  use Moola, :encoder
  alias Moola.EventType

  def encode(%EventType{} = type, options \\ []) do
    result = %{ 
     id: EventType.hashid(type),
     name: type.full_name
    }

    if options[:verbose] do
      result = Map.merge(result, %{
        description: type.description,
        parent_id: EventType.hashid(type.parent_id)
      })
    end

    Poison.Encoder.encode(result, options)
  end
end