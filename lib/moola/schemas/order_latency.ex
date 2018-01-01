defmodule Moola.OrderLatency do
  use Ecto.Schema
  import Ecto.Changeset
  alias Moola.OrderLatency

  schema "gdax_order_latency_logs" do
    field :milliseconds, :integer
    field :timestamp, :utc_datetime
  end

  @doc false
  def changeset(%OrderLatency{} = order_latency, attrs) do
    order_latency
    |> cast(attrs, [:timestamp, :milliseconds])
    |> validate_required([:timestamp, :milliseconds])
  end
end

defimpl Poison.Encoder, for: Moola.OrderLatency do
  use Moola, :encoder
  alias Decimal, as: D
  alias Moola.OrderLatency

  def encode(%OrderLatency{} = latency, options \\ []) do
    %{
      id: latency.id,
      latency: latency.milliseconds,
      timestamp: latency.timestamp
    }
    |> Poison.Encoder.encode(options)
  end

end