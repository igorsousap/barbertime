defmodule Barbertime.Schedule do
  import Ecto.Query
  alias Barbertime.Repo
  alias Barbertime.Profile.Schedule

  @doc """
  Receive a map to register appointment on the database
  ## Examples
      iex> Barbertime.Schedule.create( %{
          date: "2024-07-24",
          time: "13:30:00",
          time_service: "14:00:00"
          user_id: "5f400610-dac7-4bd0-8673-a7c0c7ce6f6b",
          service_id: "4f6e71db-8379-49c9-8999-e9802467a0fb",
          barber_shop_id: "0248ae1e-526a-4c2c-b611-bd320a119b08"
           })
  """
  @spec create(map()) :: {:ok, Schedule.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    attrs
    |> Schedule.changeset()
    |> Repo.insert()
  end

  @doc """
  Gets a all appointments by barber_shop_id.

  ## Examples

      iex> Barbertime.Schedule.get_all_by_barber_shop_id("1dfc7458-af0f-438d-8fe5-ae7272ae1559")
      %Schedule{}

      iex> Barbertime.Schedule.Services.get_all_by_barber_shop_id("unknown_barber_shop_id")
      nil

  """
  @spec get_all_by_barber_shop_id(Binary.t()) ::
          List.t() | []
  def get_all_by_barber_shop_id(barber_shop_id) when is_binary(barber_shop_id) do
    Repo.all(Schedule, barber_shop_id: barber_shop_id)
  end

  @doc """
  Gets a all appointments by user_id.

  ## Examples

      iex> Barbertime.Schedule.get_all_by_user_id("1dfc7458-af0f-438d-8fe5-ae7272ae1559")
      %Schedule{}

      iex> Barbertime.Schedule.get_all_by_user_id("unknown_barber_shop_id")
      nil

  """
  @spec get_all_by_user_id(Binary.t()) ::
          List.t() | []
  def get_all_by_user_id(user_id) when is_binary(user_id) do
    Repo.all(Schedule, user_id: user_id)
  end

  @doc """
  Gets a appointments by user_id.

  ## Examples

      iex> Barbertime.Schedule.get_by_barber_shop_id("1dfc7458-af0f-438d-8fe5-ae7272ae1559", ~D[2024-06-24], ~T[13:30:00], ~T[14:00:00])

  """
  @spec get_by_barber_shop_id_and_time(map()) ::
          {:ok, :schedule_free} | {:error, :schedule_buzy}
  def get_by_barber_shop_id_and_time(schedule)
      when is_map(schedule) do
    query =
      Schedule
      |> from()
      |> where(
        [se],
        se.date == ^schedule.date and se.barber_shop_id == ^schedule.barber_shop_id and
          fragment(
            "? < ? AND ? > ?",
            se.time,
            ^schedule.time_service,
            se.time_service,
            ^schedule.time
          )
      )

    case Repo.all(query) do
      [] -> {:ok, :schedule_free}
      _ -> {:error, :schedule_buzy}
    end
  end
end
