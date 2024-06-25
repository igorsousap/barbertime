defmodule BarbertimeWeb.BarberSessionControllerTest do
  use BarbertimeWeb.ConnCase, async: true

  import Barbertime.BarberAccountFixtures

  setup do
    %{barber: barber_fixture()}
  end

  describe "POST /barbers/log_in" do
    test "logs the barber in", %{conn: conn, barber: barber} do
      conn =
        post(conn, ~p"/barbers/log_in", %{
          "barber" => %{"email" => barber.email, "password" => valid_barber_password()}
        })

      assert get_session(conn, :barber_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ barber.email
      assert response =~ ~p"/barbers/settings"
      assert response =~ ~p"/barbers/log_out"
    end

    test "logs the barber in with remember me", %{conn: conn, barber: barber} do
      conn =
        post(conn, ~p"/barbers/log_in", %{
          "barber" => %{
            "email" => barber.email,
            "password" => valid_barber_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_barbertime_web_barber_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the barber in with return to", %{conn: conn, barber: barber} do
      conn =
        conn
        |> init_test_session(barber_return_to: "/foo/bar")
        |> post(~p"/barbers/log_in", %{
          "barber" => %{
            "email" => barber.email,
            "password" => valid_barber_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "login following registration", %{conn: conn, barber: barber} do
      conn =
        conn
        |> post(~p"/barbers/log_in", %{
          "_action" => "registered",
          "barber" => %{
            "email" => barber.email,
            "password" => valid_barber_password()
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Account created successfully"
    end

    test "login following password update", %{conn: conn, barber: barber} do
      conn =
        conn
        |> post(~p"/barbers/log_in", %{
          "_action" => "password_updated",
          "barber" => %{
            "email" => barber.email,
            "password" => valid_barber_password()
          }
        })

      assert redirected_to(conn) == ~p"/barbers/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password updated successfully"
    end

    test "redirects to login page with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/barbers/log_in", %{
          "barber" => %{"email" => "invalid@email.com", "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/barbers/log_in"
    end
  end

  describe "DELETE /barbers/log_out" do
    test "logs the barber out", %{conn: conn, barber: barber} do
      conn = conn |> log_in_barber(barber) |> delete(~p"/barbers/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :barber_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the barber is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/barbers/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :barber_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
