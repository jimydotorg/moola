defmodule Moola.Repo.Migrations.CreateCoinbaseTicks do
  use Ecto.Migration

  def change do
    create table(:coinbase_ticks) do
      add :symbol, :integer
      add :buy_price, :decimal
      add :spot_price, :decimal
      add :sell_price, :decimal
      add :latency, :integer
      add :hour, :integer
      add :minute, :integer
      add :day_of_week, :integer
      add :timestamp, :utc_datetime
    end

  end
end
