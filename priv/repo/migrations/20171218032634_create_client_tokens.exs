defmodule Moola.Repo.Migrations.CreateClientTokens do
  use Ecto.Migration

  def change do
    create table(:client_tokens) do
      add :token, :string
      add :device_id, :string
      add :last_active_at, :utc_datetime
      add :creating_ip, :string
      add :collation, :string
      add :disabled, :boolean

      timestamps()
    end

    create unique_index(:client_tokens, [:token])

  end
end
