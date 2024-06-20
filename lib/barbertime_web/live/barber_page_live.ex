defmodule BarbertimeWeb.BarberPageLive do
  use BarbertimeWeb, :live_view

  alias Barbertime.Barber.Barbers
  alias Barbertime.Barber.BarbersShop

  def mount(params, _session, socket) do
    IO.inspect(params, label: :params)
    user = Barbers.get_barber_by_email(params["email"])
    barber_shop = BarbersShop.get_all_barbershop_by_barber_id(user.id)

    socket =
      assign(socket, full_name: user.first_name, email: user.email, barber_shops: barber_shop)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Welcomer! #{@first_name}
      </.header>
      <div class="nav">
        <.label :for={barber_shop <- @barber_shop}>
          <%= barber_shop.name_store %>
        </.label>
      </div>
    </div>
    """
  end
end
