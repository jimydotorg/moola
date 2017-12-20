defmodule Moola.Repo.Migrations.CreateUserTokens do
  use Ecto.Migration

  def change do
    create table(:user_tokens) do
      add :token, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:user_tokens, [:user_id])
    create unique_index(:user_tokens, [:token])
  end
end
