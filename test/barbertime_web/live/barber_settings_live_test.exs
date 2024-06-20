defmodule BarbertimeWeb.BarberSettingsLiveTest do
  use BarbertimeWeb.ConnCase, async: true

  alias Barbertime.BarberAccount
  import Phoenix.LiveViewTest
  import Barbertime.BarberAccountFixtures

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_barber(barber_fixture())
        |> live(~p"/barbers/settings")

      assert html =~ "Change Email"
      assert html =~ "Change Password"
    end

    test "redirects if barber is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/barbers/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/barbers/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_barber_password()
      barber = barber_fixture(%{password: password})
      %{conn: log_in_barber(conn, barber), barber: barber, password: password}
    end

    test "updates the barber email", %{conn: conn, password: password, barber: barber} do
      new_email = unique_barber_email()

      {:ok, lv, _html} = live(conn, ~p"/barbers/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => password,
          "barber" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert BarberAccount.get_barber_by_email(barber.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/barbers/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "current_password" => "invalid",
          "barber" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, barber: barber} do
      {:ok, lv, _html} = live(conn, ~p"/barbers/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => "invalid",
          "barber" => %{"email" => barber.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
      assert result =~ "is not valid"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_barber_password()
      barber = barber_fixture(%{password: password})
      %{conn: log_in_barber(conn, barber), barber: barber, password: password}
    end

    test "updates the barber password", %{conn: conn, barber: barber, password: password} do
      new_password = valid_barber_password()

      {:ok, lv, _html} = live(conn, ~p"/barbers/settings")

      form =
        form(lv, "#password_form", %{
          "current_password" => password,
          "barber" => %{
            "email" => barber.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/barbers/settings"

      assert get_session(new_password_conn, :barber_token) != get_session(conn, :barber_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert BarberAccount.get_barber_by_email_and_password(barber.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/barbers/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "current_password" => "invalid",
          "barber" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/barbers/settings")

      result =
        lv
        |> form("#password_form", %{
          "current_password" => "invalid",
          "barber" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      barber = barber_fixture()
      email = unique_barber_email()

      token =
        extract_barber_token(fn url ->
          BarberAccount.deliver_barber_update_email_instructions(%{barber | email: email}, barber.email, url)
        end)

      %{conn: log_in_barber(conn, barber), token: token, email: email, barber: barber}
    end

    test "updates the barber email once", %{conn: conn, barber: barber, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/barbers/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/barbers/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute BarberAccount.get_barber_by_email(barber.email)
      assert BarberAccount.get_barber_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/barbers/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/barbers/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, barber: barber} do
      {:error, redirect} = live(conn, ~p"/barbers/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/barbers/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert BarberAccount.get_barber_by_email(barber.email)
    end

    test "redirects if barber is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/barbers/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/barbers/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end
