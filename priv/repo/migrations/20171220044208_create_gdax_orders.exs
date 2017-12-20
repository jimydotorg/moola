defmodule Moola.Repo.Migrations.CreateGdaxOrders do
  use Ecto.Migration

  def change do
    create table(:gdax_orders) do
      add :gdax_id, :string
      add :price, :float
      add :size, :float
      add :symbol, :integer
      add :product_id, :string
      add :side, :string
      add :stp, :string
      add :type, :string
      add :time_in_force, :string
      add :post_only, :boolean, default: false, null: false
      add :created_at, :utc_datetime
      add :fill_fees, :float
      add :filled_size, :float
      add :executed_value, :float
      add :status, :string
      add :settled, :boolean, default: false, null: false

      timestamps()
    end

  end
end
