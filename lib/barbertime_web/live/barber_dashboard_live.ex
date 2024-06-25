defmodule BarbertimeWeb.BarberDashboardLive do
  use BarbertimeWeb, :live_view

  alias Barbertime.BarbersShop

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Barber</h1>
    <div></div>
    """
  end
end
