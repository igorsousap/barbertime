defmodule Barbertime.Repo.Migrations.AddScheduleTable do
  use Ecto.Migration

  def change do
    create table(:schedules) do
      add :date, :date, null: false
      add :time, :time, null: false
      add :time_service, :time, null: false
      add :status, :string, default: "pending", null: false
      add :user_id, references(:users, on_delete: :delete_all, type: :uuid), null: false

      add :barber_shop_id, references(:barber_shop, on_delete: :delete_all, type: :uuid),
        null: false

      add :service_id, references(:services, on_delete: :delete_all, type: :uuid), null: false

      timestamps()
    end

    create index(:schedules, [:user_id], name: :schedules_user_id_fkey)
    create index(:schedules, [:barber_shop_id], name: :schedules_barber_shop_id_fkey)
    create index(:schedules, [:service_id], name: :schedules_service_id_fkey)
  end

  defp create_size_types_enum do
    query_create_type = "CREATE TYPE status AS ENUM ('pending' 'confirmed', 'canceled')"

    query_create_type_rollback = "DROP TYPE status"

    execute query_create_type, query_create_type_rollback
  end
end
