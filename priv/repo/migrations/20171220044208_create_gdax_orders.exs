defmodule Moola.Repo.Migrations.CreateGdaxOrders do
  use Ecto.Migration

  def change do
    create table(:gdax_orders) do
      add :gdax_id, :string
      add :price, :decimal
      add :size, :decimal
      add :symbol, :integer
      add :product_id, :string
      add :side, :string
      add :stp, :string
      add :type, :string
      add :time_in_force, :string
      add :post_only, :boolean, default: false, null: false
      add :fill_fees, :decimal
      add :filled_size, :decimal
      add :executed_value, :decimal
      add :status, :string
      add :settled, :boolean, default: false, null: false
      add :created_at, :utc_datetime
    end

    create unique_index(:gdax_orders, [:gdax_id])
    create index(:gdax_orders, [:symbol])

  end
end
