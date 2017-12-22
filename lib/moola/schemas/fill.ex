defmodule Moola.Fill do
  use Moola, :schema
  alias Moola.Fill

  schema "gdax_fills" do
    field :trade_id, :integer
    field :symbol, Moola.Enum.Symbol
    field :order_id, :string
    field :created_at, :utc_datetime
    field :fee, :decimal
    field :liquidity, :string
    field :price, :decimal
    field :product_id, :string
    field :settled, :boolean, default: false
    field :side, :string
    field :size, :decimal
  end

  @doc false
  def changeset(%Fill{} = fill, attrs) do

    attrs = attrs
    |> Map.put("symbol", downcase(attrs["product_id"]))

    fill
    |> cast(attrs, [:trade_id, :symbol, :product_id, :price, :size, :order_id, :created_at, :liquidity, :fee, :settled, :side])
    |> validate_required([:trade_id, :symbol, :product_id, :price, :size, :order_id, :created_at, :liquidity, :fee, :settled, :side])
  end
end
