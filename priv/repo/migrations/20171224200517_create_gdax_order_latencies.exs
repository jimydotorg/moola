defmodule Moola.Repo.Migrations.CreateGdaxOrderLatencies do
  use Ecto.Migration

  def change do
    create table(:gdax_order_latency_logs) do
      add :milliseconds, :integer
      add :timestamp, :utc_datetime
    end

    create index(:gdax_order_latency_logs, [:timestamp])
  end
end
