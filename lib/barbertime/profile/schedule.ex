defmodule Barbertime.Profile.Schedule do
  use Ecto.Schema
  import Ecto.Changeset
  @type status_types :: :pending | :confirmed | :canceled
  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          date: Date.t(),
          time: Time.t(),
          time_service: Time.t(),
          status: status_types(),
          user_id: Ecto.UUID.t(),
          barber_shop_id: Ecto.UUID.t(),
          service_id: Ecto.UUID.t()
        }

  @fields ~w(date time status user_id barber_shop_id service_id)a
  @status_types ~w(pending confirmed canceled)a

  schema "schedules" do
    field :date, :date
    field :time, :time
    field :time_service, :time
    field :status, Ecto.Enum, values: @status_types, default: :pending
    field :user_id, :binary_id
    field :barber_shop_id, :binary_id
    field :service_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc """
  Receive a schdule map to create a changeset
  Example
  iex> Barbertime.Profile.Schedule.changeset(
          %{
          date: "2024-07-24",
          time: "13:30:00",
          time_service: "14:00:00"
          user_id: Ecto.UUID.autogenerate(),
          service_id: Ecto.UUID.autogenerate(),
          barber_shop_id: Ecto.UUID.autogenerate()
           })
  """
  @spec changeset(:__MODULE__.t(), map()) :: Ecto.Changeset.t()
  def changeset(schedule \\ %__MODULE__{}, attrs) do
    schedule
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> validate_subset(:status, @status_types)
    |> foreign_key_constraint(:users)
    |> foreign_key_constraint(:barbers)
    |> foreign_key_constraint(:services)
  end
end
