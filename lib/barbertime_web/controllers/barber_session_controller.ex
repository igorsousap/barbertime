defmodule BarbertimeWeb.BarberSessionController do
  use BarbertimeWeb, :controller

  alias Barbertime.BarberAccount
  alias BarbertimeWeb.BarberAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:barber_return_to, ~p"/barbers/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"barber" => barber_params}, info) do
    %{"email" => email, "password" => password} = barber_params

    if barber = BarberAccount.get_barber_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> BarberAuth.log_in_barber(barber, barber_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/barbers/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> BarberAuth.log_out_barber()
  end
end
