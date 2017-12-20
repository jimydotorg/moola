defmodule Moola.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :nickname, :string
      add :password_hash, :string
      add :registration_ip, :string
      add :status, :integer
      add :level, :integer
      add :deleted_nickname, :string
      add :deleted_at, :utc_datetime
      timestamps()
    end

    create unique_index(:users, [:nickname])
  end
end
