defmodule BarbertimeWeb.PageLive do
  use BarbertimeWeb, :live_view

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form_barber = to_form(%{"email" => email}, as: "barber")

    {:ok, assign(socket, form_barber: form_barber), temporary_assigns: [form_barber: form_barber]}
  end

  def render(assigns) do
    ~H"""
    <table align="left" l>
      <div class="mx-auto max-w-sm">
        <.header class="text-center">
          Don't have an account? Create your barber account
          <:subtitle>
            <.link navigate={~p"/barbers/register"} class="font-semibold text-brand hover:underline">
              Sign up as Barber
            </.link>
            for an account now.
          </:subtitle>
        </.header>
      </div>
    </table>
    <table align="left" l>
      <div class="mx-auto max-w-sm">
        <.header class="text-center">
          Don't have an account? Create your user account
          <:subtitle>
            <.link navigate={~p"/users/register"} class="font-semibold text-brand hover:underline">
              Sign up as User
            </.link>
            for an account now.
          </:subtitle>
        </.header>
      </div>
    </table>
    """
  end
end
