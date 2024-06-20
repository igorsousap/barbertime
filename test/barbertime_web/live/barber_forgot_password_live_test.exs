defmodule BarbertimeWeb.BarberForgotPasswordLiveTest do
  use BarbertimeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Barbertime.BarberAccountFixtures

  alias Barbertime.BarberAccount
  alias Barbertime.Repo

  describe "Forgot password page" do
    test "renders email page", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/barbers/reset_password")

      assert html =~ "Forgot your password?"
      assert has_element?(lv, ~s|a[href="#{~p"/barbers/register"}"]|, "Register")
      assert has_element?(lv, ~s|a[href="#{~p"/barbers/log_in"}"]|, "Log in")
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_barber(barber_fixture())
        |> live(~p"/barbers/reset_password")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end
  end

  describe "Reset link" do
    setup do
      %{barber: barber_fixture()}
    end

    test "sends a new reset password token", %{conn: conn, barber: barber} do
      {:ok, lv, _html} = live(conn, ~p"/barbers/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", barber: %{"email" => barber.email})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"

      assert Repo.get_by!(BarberAccount.BarberToken, barber_id: barber.id).context ==
               "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/barbers/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", barber: %{"email" => "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"
      assert Repo.all(BarberAccount.BarberToken) == []
    end
  end
end
