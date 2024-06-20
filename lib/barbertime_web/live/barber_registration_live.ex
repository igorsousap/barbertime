defmodule BarbertimeWeb.BarberRegistrationLive do
  use BarbertimeWeb, :live_view

  alias Barbertime.BarberAccount
  alias Barbertime.BarberAccount.Barber

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Register for an account
        <:subtitle>
          Already registered?
          <.link navigate={~p"/barbers/log_in"} class="font-semibold text-brand hover:underline">
            Log in
          </.link>
          to your account now.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/barbers/log_in?_action=registered"}
        method="post"
      >
        <.error :if={@check_errors}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />
        <.input field={@form[:first_name]} type="text" label="First Name" required />
        <.input field={@form[:last_name]} type="text" label="Second Name" required />

        <:actions>
          <.button phx-disable-with="Creating account..." class="w-full">Create an account</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = BarberAccount.change_barber_registration(%Barber{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"barber" => barber_params}, socket) do
    case BarberAccount.register_barber(barber_params) do
      {:ok, barber} ->
        {:ok, _} =
          BarberAccount.deliver_barber_confirmation_instructions(
            barber,
            &url(~p"/barbers/confirm/#{&1}")
          )

        changeset = BarberAccount.change_barber_registration(barber)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"barber" => barber_params}, socket) do
    changeset = BarberAccount.change_barber_registration(%Barber{}, barber_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "barber")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
