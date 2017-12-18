defmodule Moola.Repo.Migrations.CreateTicks do
  use Ecto.Migration

  def change do
    create table(:ticks) do
      add :symbol, :integer
      add :price, :float
      add :max_price, :float
      add :min_price, :float
      add :volume, :float
      add :usd_volume, :float 

      add :hour, :integer
      add :minute, :integer
      add :day_of_week, :integer
      add :timestamp, :utc_datetime
    end

    create index(:ticks, [:symbol, :timestamp])

  end
end
