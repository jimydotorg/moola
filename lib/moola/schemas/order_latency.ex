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
