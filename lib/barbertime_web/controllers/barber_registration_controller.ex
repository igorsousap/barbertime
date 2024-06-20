defmodule BarbertimeWeb.BarberRegistrationController do
  use BarbertimeWeb, :controller

  alias Barbertime.Barber.Barbers

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"barber" => barber_params}, info) do
    %{"email" => email, "password" => password} = barber_params

    case Barbers.get_barber_by_email_and_password(email, password) do
      nil ->
        conn
        |> put_flash(:error, "Invalid email or password")
        |> put_flash(:email, String.slice(email, 0, 160))
        |> redirect(to: ~p"/barber/log_in")

      {:ok, _user} ->
        conn
        |> put_flash(:info, info)
        |> redirect(to: ~p"/")
    end
  end
end
