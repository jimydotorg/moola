defmodule Moola.Order do
  use Moola, :schema
  alias Moola.Order

  schema "gdax_orders" do
    field :created_at, :utc_datetime
    field :executed_value, :float
    field :fill_fees, :float
    field :filled_size, :float
    field :gdax_id, :string
    field :post_only, :boolean, default: false
    field :price, :float
    field :product_id, :string
    field :settled, :boolean, default: false
    field :side, :string
    field :size, :float
    field :status, :string
    field :stp, :string
    field :symbol, :integer
    field :time_in_force, :string
    field :type, :string

    timestamps()
  end

  def changeset(%Order{} = order, %{"id" => id} = gdax_attrs) do
    attrs = gdax_attrs
    |> Map.put("gdax_id", id)
    |> Map.delete("id")
    changeset(order, attrs)
  end

  @doc false
  def changeset(%Order{} = order, attrs) do
    order
    |> cast(attrs, [:gdax_id, :price, :size, :symbol, :product_id, :side, :stp, :type, :time_in_force, :post_only, :created_at, :fill_fees, :filled_size, :executed_value, :status, :settled])
    |> validate_required([:gdax_id, :price, :size, :symbol, :product_id, :side, :stp, :type, :time_in_force, :post_only, :created_at, :fill_fees, :filled_size, :executed_value, :status, :settled])
  end
end
