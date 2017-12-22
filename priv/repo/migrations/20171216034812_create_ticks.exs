defmodule Moola.Repo.Migrations.CreateTicks do
  use Ecto.Migration

  def change do
    create table(:ticks) do
      add :symbol, :integer
      add :price, :decimal
      add :max_price, :decimal
      add :min_price, :decimal
      add :volume, :decimal
      add :usd_volume, :decimal 

      add :hour, :integer
      add :minute, :integer
      add :day_of_week, :integer
      add :timestamp, :utc_datetime
    end

    create index(:ticks, [:symbol, :timestamp])

  end
end
