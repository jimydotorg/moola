defmodule Moola.Repo.Migrations.CreateBinanceTicks do
  use Ecto.Migration

  def change do
    create table(:binance_ticks) do
      add :symbol, :integer
      add :price, :decimal
      add :max_price, :decimal
      add :min_price, :decimal
      add :volume, :decimal
      add :btc_volume, :decimal 
      add :usd_volume, :decimal 
      add :hour, :integer
      add :minute, :integer
      add :day_of_week, :integer
      add :timestamp, :utc_datetime
    end

    create index(:binance_ticks, [:symbol, :timestamp])

  end
end
