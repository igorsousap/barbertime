defmodule Barbertime.Repo.Migrations.CreateBarbersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:barbers, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :email, :citext, null: false
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps(type: :utc_datetime)
    end

    create unique_index(:barbers, [:email])

    create table(:barbers_tokens) do
      add :barber_id, references(:barbers, on_delete: :delete_all, column: :id, type: :uuid),
        null: false

      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:barbers_tokens, [:barber_id])
    create unique_index(:barbers_tokens, [:context, :token])
  end
end
