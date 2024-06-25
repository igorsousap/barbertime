defmodule BarbertimeWeb.BarberAuthTest do
  use BarbertimeWeb.ConnCase, async: true

  alias Phoenix.LiveView
  alias Barbertime.BarberAccount
  alias BarbertimeWeb.BarberAuth
  import Barbertime.BarberAccountFixtures

  @remember_me_cookie "_barbertime_web_barber_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, BarbertimeWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{barber: barber_fixture(), conn: conn}
  end

  describe "log_in_barber/3" do
    test "stores the barber token in the session", %{conn: conn, barber: barber} do
      conn = BarberAuth.log_in_barber(conn, barber)
      assert token = get_session(conn, :barber_token)
      assert get_session(conn, :live_socket_id) == "barbers_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == ~p"/"
      assert BarberAccount.get_barber_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, barber: barber} do
      conn = conn |> put_session(:to_be_removed, "value") |> BarberAuth.log_in_barber(barber)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, barber: barber} do
      conn = conn |> put_session(:barber_return_to, "/hello") |> BarberAuth.log_in_barber(barber)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, barber: barber} do
      conn = conn |> fetch_cookies() |> BarberAuth.log_in_barber(barber, %{"remember_me" => "true"})
      assert get_session(conn, :barber_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :barber_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_barber/1" do
    test "erases session and cookies", %{conn: conn, barber: barber} do
      barber_token = BarberAccount.generate_barber_session_token(barber)

      conn =
        conn
        |> put_session(:barber_token, barber_token)
        |> put_req_cookie(@remember_me_cookie, barber_token)
        |> fetch_cookies()
        |> BarberAuth.log_out_barber()

      refute get_session(conn, :barber_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
      refute BarberAccount.get_barber_by_session_token(barber_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "barbers_sessions:abcdef-token"
      BarbertimeWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> BarberAuth.log_out_barber()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if barber is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> BarberAuth.log_out_barber()
      refute get_session(conn, :barber_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "fetch_current_barber/2" do
    test "authenticates barber from session", %{conn: conn, barber: barber} do
      barber_token = BarberAccount.generate_barber_session_token(barber)
      conn = conn |> put_session(:barber_token, barber_token) |> BarberAuth.fetch_current_barber([])
      assert conn.assigns.current_barber.id == barber.id
    end

    test "authenticates barber from cookies", %{conn: conn, barber: barber} do
      logged_in_conn =
        conn |> fetch_cookies() |> BarberAuth.log_in_barber(barber, %{"remember_me" => "true"})

      barber_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> BarberAuth.fetch_current_barber([])

      assert conn.assigns.current_barber.id == barber.id
      assert get_session(conn, :barber_token) == barber_token

      assert get_session(conn, :live_socket_id) ==
               "barbers_sessions:#{Base.url_encode64(barber_token)}"
    end

    test "does not authenticate if data is missing", %{conn: conn, barber: barber} do
      _ = BarberAccount.generate_barber_session_token(barber)
      conn = BarberAuth.fetch_current_barber(conn, [])
      refute get_session(conn, :barber_token)
      refute conn.assigns.current_barber
    end
  end

  describe "on_mount :mount_current_barber" do
    test "assigns current_barber based on a valid barber_token", %{conn: conn, barber: barber} do
      barber_token = BarberAccount.generate_barber_session_token(barber)
      session = conn |> put_session(:barber_token, barber_token) |> get_session()

      {:cont, updated_socket} =
        BarberAuth.on_mount(:mount_current_barber, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_barber.id == barber.id
    end

    test "assigns nil to current_barber assign if there isn't a valid barber_token", %{conn: conn} do
      barber_token = "invalid_token"
      session = conn |> put_session(:barber_token, barber_token) |> get_session()

      {:cont, updated_socket} =
        BarberAuth.on_mount(:mount_current_barber, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_barber == nil
    end

    test "assigns nil to current_barber assign if there isn't a barber_token", %{conn: conn} do
      session = conn |> get_session()

      {:cont, updated_socket} =
        BarberAuth.on_mount(:mount_current_barber, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_barber == nil
    end
  end

  describe "on_mount :ensure_authenticated" do
    test "authenticates current_barber based on a valid barber_token", %{conn: conn, barber: barber} do
      barber_token = BarberAccount.generate_barber_session_token(barber)
      session = conn |> put_session(:barber_token, barber_token) |> get_session()

      {:cont, updated_socket} =
        BarberAuth.on_mount(:ensure_authenticated, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_barber.id == barber.id
    end

    test "redirects to login page if there isn't a valid barber_token", %{conn: conn} do
      barber_token = "invalid_token"
      session = conn |> put_session(:barber_token, barber_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: BarbertimeWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = BarberAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_barber == nil
    end

    test "redirects to login page if there isn't a barber_token", %{conn: conn} do
      session = conn |> get_session()

      socket = %LiveView.Socket{
        endpoint: BarbertimeWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = BarberAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_barber == nil
    end
  end

  describe "on_mount :redirect_if_barber_is_authenticated" do
    test "redirects if there is an authenticated  barber ", %{conn: conn, barber: barber} do
      barber_token = BarberAccount.generate_barber_session_token(barber)
      session = conn |> put_session(:barber_token, barber_token) |> get_session()

      assert {:halt, _updated_socket} =
               BarberAuth.on_mount(
                 :redirect_if_barber_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end

    test "doesn't redirect if there is no authenticated barber", %{conn: conn} do
      session = conn |> get_session()

      assert {:cont, _updated_socket} =
               BarberAuth.on_mount(
                 :redirect_if_barber_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end
  end

  describe "redirect_if_barber_is_authenticated/2" do
    test "redirects if barber is authenticated", %{conn: conn, barber: barber} do
      conn = conn |> assign(:current_barber, barber) |> BarberAuth.redirect_if_barber_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "does not redirect if barber is not authenticated", %{conn: conn} do
      conn = BarberAuth.redirect_if_barber_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_barber/2" do
    test "redirects if barber is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> BarberAuth.require_authenticated_barber([])
      assert conn.halted

      assert redirected_to(conn) == ~p"/barbers/log_in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> BarberAuth.require_authenticated_barber([])

      assert halted_conn.halted
      assert get_session(halted_conn, :barber_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> BarberAuth.require_authenticated_barber([])

      assert halted_conn.halted
      assert get_session(halted_conn, :barber_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> BarberAuth.require_authenticated_barber([])

      assert halted_conn.halted
      refute get_session(halted_conn, :barber_return_to)
    end

    test "does not redirect if barber is authenticated", %{conn: conn, barber: barber} do
      conn = conn |> assign(:current_barber, barber) |> BarberAuth.require_authenticated_barber([])
      refute conn.halted
      refute conn.status
    end
  end
end
