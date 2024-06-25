defmodule BarbertimeWeb.BarberConfirmationLiveTest do
  use BarbertimeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Barbertime.BarberAccountFixtures

  alias Barbertime.BarberAccount
  alias Barbertime.Repo

  setup do
    %{barber: barber_fixture()}
  end

  describe "Confirm barber" do
    test "renders confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/barbers/confirm/some-token")
      assert html =~ "Confirm Account"
    end

    test "confirms the given token once", %{conn: conn, barber: barber} do
      token =
        extract_barber_token(fn url ->
          BarberAccount.deliver_barber_confirmation_instructions(barber, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/barbers/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Barber confirmed successfully"

      assert BarberAccount.get_barber!(barber.id).confirmed_at
      refute get_session(conn, :barber_token)
      assert Repo.all(BarberAccount.BarberToken) == []

      # when not logged in
      {:ok, lv, _html} = live(conn, ~p"/barbers/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Barber confirmation link is invalid or it has expired"

      # when logged in
      conn =
        build_conn()
        |> log_in_barber(barber)

      {:ok, lv, _html} = live(conn, ~p"/barbers/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, barber: barber} do
      {:ok, lv, _html} = live(conn, ~p"/barbers/confirm/invalid-token")

      {:ok, conn} =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Barber confirmation link is invalid or it has expired"

      refute BarberAccount.get_barber!(barber.id).confirmed_at
    end
  end
end
