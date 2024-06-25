defmodule Barbertime.ScheduleService do
  alias Barbertime.{BarberService, Schedule}

  @spec scheduler(map()) ::
          {:ok, Schedule.t()} | {:error, Ecto.Changeset.t()} | {:error, :schedule_buzy}
  def scheduler(schedule) do
    date = Date.from_iso8601(schedule["date"])
    time = Time.from_iso8601(schedule["time"])
    service = BarberService.by_id(schedule["service_id"])
    time_service = Time.add(time, service["duration"], :minute)

    case Schedule.get_by_barber_shop_id_and_time(
           schedule.barber_shop_id,
           date,
           time,
           time_service
         ) do
      {:ok, :schedule_free} ->
        schedule_params =
          build_schedule(
            schedule.barber_shop_id,
            schedule.service_id,
            schedule.user_id,
            date,
            time,
            time_service
          )

        Schedule.create(schedule_params)

      {:error, :schedule_buzy} ->
        {:error, :schedule_buzy}
    end
  end

  defp build_schedule(barber_shop_id, service_id, user_id, date, time, time_service) do
    %{
      barber_shop_id: barber_shop_id,
      service_id: service_id,
      user_id: user_id,
      data: date,
      time: time,
      time_service: time_service
    }
  end
end
