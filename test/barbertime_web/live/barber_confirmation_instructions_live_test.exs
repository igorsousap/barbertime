defmodule BarbertimeWeb.BarberConfirmationInstructionsLiveTest do
  use BarbertimeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Barbertime.BarberAccountFixtures

  alias Barbertime.BarberAccount
  alias Barbertime.Repo

  setup do
    %{barber: barber_fixture()}
  end

  describe "Resend confirmation" do
    test "renders the resend confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/barbers/confirm")
      assert html =~ "Resend confirmation instructions"
    end

    test "sends a new confirmation token", %{conn: conn, barber: barber} do
      {:ok, lv, _html} = live(conn, ~p"/barbers/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", barber: %{email: barber.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.get_by!(BarberAccount.BarberToken, barber_id: barber.id).context == "confirm"
    end

    test "does not send confirmation token if barber is confirmed", %{conn: conn, barber: barber} do
      Repo.update!(BarberAccount.Barber.confirm_changeset(barber))

      {:ok, lv, _html} = live(conn, ~p"/barbers/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", barber: %{email: barber.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      refute Repo.get_by(BarberAccount.BarberToken, barber_id: barber.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/barbers/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", barber: %{email: "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.all(BarberAccount.BarberToken) == []
    end
  end
end
