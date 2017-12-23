defmodule Moola.Repo.Migrations.CreateFills do
  use Ecto.Migration

  def change do
    create table(:gdax_fills) do
      add :trade_id, :integer
      add :symbol, :integer
      add :order_id, :string
      add :product_id, :string
      add :price, :decimal
      add :size, :decimal
      add :liquidity, :string
      add :fee, :decimal
      add :settled, :boolean, default: false, null: false
      add :side, :string
      add :created_at, :utc_datetime
    end

    create unique_index(:gdax_fills, [:trade_id, :symbol])
    create index(:gdax_fills, [:symbol])

  end
end
