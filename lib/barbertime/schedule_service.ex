defmodule Barbertime.ScheduleService do
  alias Barbertime.{BarberService, Schedule}

  @spec scheduler(map()) ::
          {:ok, Schedule.t()} | {:error, Ecto.Changeset.t()} | {:error, :schedule_buzy}
  def scheduler(schedule) do
    schedule_updated =
      schedule
      |> build_date_time()
      |> get_time_service()
      |> build_schedule()

    case Schedule.get_by_barber_shop_id_and_time(schedule_updated) do
      {:ok, :schedule_free} ->
        Schedule.create(schedule_updated)

      {:error, :schedule_buzy} ->
        {:error, :schedule_buzy}
    end
  end

  defp build_schedule(schedule) do
    %{
      barber_shop_id: schedule["barber_shop_id"],
      service_id: schedule["service_id"],
      user_id: schedule["user_id"],
      data: schedule["date"],
      time: schedule["time"],
      time_service: schedule["time_service"]
    }
  end

  defp build_date_time(schedule) do
    date = Date.from_iso8601(schedule["date"])
    time = Time.from_iso8601(schedule["time"])

    %{schedule | time: time, date: date}
  end

  defp get_time_service(schedule) do
    service = BarberService.by_id(schedule["service_id"])
    time_service = Time.add(schedule.time, service["duration"], :minute)

    schedule = Map.put(schedule, "time_service", time_service)

    schedule
  end
end
