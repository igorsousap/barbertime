defmodule Barbertime.Repo.Migrations.AddsBarbersAndBarberShopTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:barber, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:barber, [:email], name: :barber_email_index)

    create table(:barber_shop, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name_store, :string, required: true
      add :adress, :string, required: true
      add :number, :integer, required: true
      add :cep, :string, required: true
      add :cnpj, :string, required: true
      add :phone, :string, require: true

      add :barber_id,
          references(:barber, on_delete: :delete_all, column: :id, type: :uuid),
          null: false

      timestamps()
    end

    create unique_index(:barber_shop, [:name_store], name: :barber_shop_name_index)
    create unique_index(:barber_shop, [:cnpj], name: :barber_shop_cnpj_index)

    create table(:services, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, required: true
      add :price, :decimal, required: true
      add :duration, :integer, required: true

      add :barber_shop_id,
          references(:barber_shop, on_delete: :delete_all, column: :id, type: :uuid),
          null: false

      timestamps()
    end
  end
end
