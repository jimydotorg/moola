defmodule Moola.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:log_event_types) do
      add :name, :string
      add :full_name, :text
      add :description, :string
      add :parent_id, references(:log_event_types, on_delete: :nothing)

      timestamps()
    end

    create index(:log_event_types, [:parent_id])
    create index(:log_event_types, [:full_name])
    create index(:log_event_types, [:name, :parent_id], unique: true)

    create table(:log_events) do
      add :client_token_id, references(:client_tokens, on_delete: :nothing)
      add :log_event_type_id, references(:log_event_types, on_delete: :nothing)
      add :info, :map      
      timestamps()
    end

    alter table(:log_events) do
      remove :updated_at
    end

    create index(:log_events, [:client_token_id])
    create index(:log_events, [:log_event_type_id])
  end
end
