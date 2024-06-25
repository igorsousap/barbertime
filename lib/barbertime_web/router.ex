defmodule BarbertimeWeb.Router do
  alias BarbertimeWeb.BarberPageLive
  use BarbertimeWeb, :router

  import BarbertimeWeb.UserAuth

  import BarbertimeWeb.BarberAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BarbertimeWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug :fetch_current_barber
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BarbertimeWeb do
    pipe_through [:browser, :require_authenticated_barber]

    live "/barber/dashboard", BarberDashboardLive
  end

  scope "/", BarbertimeWeb do
    pipe_through :browser
    live "/barber/register", BarberRegistrationLive, :new
    live "/barber/log_in", BarberLoginLive, :new
    live "/barber/live", BarberPageLive
    live "/", PageLive, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", BarbertimeWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:barbertime, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BarbertimeWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", BarbertimeWeb do
    pipe_through [:browser, :redirect_if_barber_is_authenticated]

    live_session :redirect_if_barber_is_authenticated,
      on_mount: [{BarbertimeWeb.BarberAuth, :redirect_if_barber_is_authenticated}] do
      live "/barbers/register", BarberRegistrationLive, :new
      live "/barbers/log_in", BarberLoginLive, :new
      live "/barbers/reset_password", BarberForgotPasswordLive, :new
      live "/barbers/reset_password/:token", BarberResetPasswordLive, :edit
    end

    post "/barbers/log_in", BarberSessionController, :create
  end

  scope "/", BarbertimeWeb do
    pipe_through [:browser, :require_authenticated_barber]

    live_session :require_authenticated_barber,
      on_mount: [{BarbertimeWeb.BarberAuth, :ensure_authenticated}] do
      live "/barbers/settings", BarberSettingsLive, :edit
      live "/barbers/settings/confirm_email/:token", BarberSettingsLive, :confirm_email
    end
  end

  scope "/", BarbertimeWeb do
    pipe_through [:browser]

    delete "/barbers/log_out", BarberSessionController, :delete

    live_session :current_barber,
      on_mount: [{BarbertimeWeb.BarberAuth, :mount_current_barber}] do
      live "/barbers/confirm/:token", BarberConfirmationLive, :edit
      live "/barbers/confirm", BarberConfirmationInstructionsLive, :new
    end
  end

  ## Authentication routes

  scope "/", BarbertimeWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{BarbertimeWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", BarbertimeWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{BarbertimeWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", BarbertimeWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{BarbertimeWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
