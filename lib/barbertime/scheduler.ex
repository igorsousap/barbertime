defmodule Barbertime.Scheduler do
  import Ecto.Query
  alias Barbertime.Repo
  alias Barbertime.Profile.Schedule

  @doc """
  Receive a map to register appointment on the database
  ## Examples
      iex> Barbertime.Scheduler.create( %{
          date: "2024-07-01",
          time: "13:30:00",
          time_service: "14:00:00",
          user_id: "0f4d68ca-4cd1-49d9-8ace-2722d0c69bd1",
          service_id: "5a2589f8-ae6a-46a7-b266-cef6d4a04036",
          barber_shop_id: "0aedbe7c-d65c-4ed3-ad79-6f2c85a15b4a"
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
  def get_all_by_barber_shop_id(barber_shop_id \\ "non_id_existing")
      when is_binary(barber_shop_id) do
    today = Date.utc_today()

    Schedule
    |> from()
    |> where([se], se.date > ^today and se.status != :canceled)
    |> Repo.all(barber_shop_id: barber_shop_id)
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
