defmodule BarbertimeWeb.PageLive do
  use BarbertimeWeb, :live_view

  def mount(_params, _session, socket) do
    IO.inspect(socket)
    {:ok, assign(socket, number: 7)}
  end

  def render(assigns) do
    IO.inspect(assigns, label: :assings)

    ~H"""
    <%= @number %>
    <.button phx-click="add">Add</.button>
    """
  end

  def handle_event("add", _params, socket) do
    {:noreply, assign(socket, number: socket.assigns.number + 1)}
  end
end
