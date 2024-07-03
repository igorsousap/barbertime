defmodule BarbertimeWeb.BarberDashboardLive do
  alias Barbertime.BarberService
  use BarbertimeWeb, :live_view

  alias Barbertime.{BarbersShop, BarberService, Scheduler}
  alias Barbertime.Profile.Schedule
  alias Barbertime.BarberShop.{Shop, Service}

  on_mount {BarbertimeWeb.BarberAuth, :mount_current_barber}

  def render(%{loading: true} = assigns) do
    ~H"""
    <h1>Barber Shop is loading ...</h1>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      form =
        %Shop{}
        |> BarbersShop.create_changeset(%{})
        |> to_form(as: "shop")

      form_service =
        %Service{}
        |> BarberService.create_changeset(%{})
        |> to_form(as: "service")

      socket =
        socket
        |> assign(form: form, loading: false)
        |> assign(form: form_service, loading: false)
        |> stream(:services, BarberService.list_all(socket.assigns.current_barber.barber_shop.id))
        |> stream(
          :schedules,
          Scheduler.get_all_by_barber_shop_id(socket.assigns.current_barber.barber_shop.id)
        )

      {:ok, socket}
    else
      {:ok, assign(socket, loading: true)}
    end
  end

  def render(assigns) do
    ~H"""
    <h1 class="w-1/2 mx-auto flex gap-2 p-4 border">Barber Shop</h1>

    <div id="shop" , phx-update="stream" class="flex flex-col gap-2">
      <div class="w-1/2 mx-auto flex clex-col gap-2 p-4 border rounder">
        <p>
          <%= if @current_barber.barber_shop do %>
            <p><%= @current_barber.barber_shop.name_store %></p>
            <.button
              class="w-1/2 mx-auto flex gap-2 p-4 border"
              type="button"
              phx-click={show_modal("new-service-model")}
            >
              Create Service
            </.button>

            <.button
              class="w-1/2 mx-auto flex gap-2 p-4 border"
              type="button"
              phx-click={show_modal("show-service-model")}
            >
              Show Service
            </.button>
          <% else %>
            <.button
              class="w-1/2 mx-auto flex gap-2 p-4 border"
              type="button"
              phx-click={show_modal("new-shop-model")}
            >
              Create Shop
            </.button>

            <p>Store Not Created</p>
          <% end %>
        </p>
      </div>

      <div
        :for={
          {dom_id, schedule} <-
            @streams.schedules
        }
        id={dom_id}
        class="w-1/2 mx-auto gap-2 p-4 border rounded"
      >
        <p>Date: <%= schedule.date %></p>
        <p>Start: <%= schedule.time %></p>
        <p>End: <%= schedule.time_service %></p>
        <p>Status: <%= schedule.status %></p>
      </div>
    </div>

    <div id="services" phx-update="stream" class="flex gap-2"></div>

    <.modal id="new-shop-model">
      <.simple_form for={@form} phx-change="validate" phx-submit="save-shop">
        <.input field={@form[:name_store]} type="text" label="Store Name" required />
        <.input field={@form[:adress]} type="text" label="Adress" required />
        <.input field={@form[:number]} type="number" label="Number" required />
        <.input field={@form[:cep]} type="text" label="CEP" required />
        <.input field={@form[:cnpj]} type="text" label="CNPJ" required />
        <.input field={@form[:phone]} type="text" label="Phone" required />
        <.button type="submit" phx-disable-with="Create">Create Barber Shop</.button>
      </.simple_form>
    </.modal>

    <.modal id="new-service-model">
      <.simple_form for={@form} phx-change="validate" phx-submit="save-service">
        <.input field={@form[:name]} type="text" label="Service Name" required />
        <.input field={@form[:price]} type="text" label="Price" required />
        <.input field={@form[:duration]} type="number" label="Duration (in minutes)" required />
        <.button type="submit" phx-disable-with="Create">Create Service</.button>
      </.simple_form>
    </.modal>

    <.modal id="show-service-model">
      <div
        :for={
          {dom_id, service} <-
            @streams.services
        }
        id={dom_id}
        class="w-1/2 mx-auto gap-2 p-4 border rounded"
      >
        <p>Type: <%= service.name %></p>
        <p>Price: <%= service.price %></p>
        <p>Duration: <%= service.duration %> Minutes</p>
      </div>
    </.modal>
    """
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save-shop", %{"shop" => shop_params}, socket) do
    %{current_barber: barber} = socket.assigns

    shop_params
    |> Map.put("barber_id", barber.id)
    |> BarbersShop.create()
    |> case do
      {:ok, shop} ->
        socket =
          socket
          |> assign(:service, shop)
          |> put_flash(:info, "Shop Created successfuly")
          |> push_navigate(to: ~p"/barber/dashboard")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  def handle_event("save-service", %{"service" => service_params}, socket) do
    %{current_barber: barber} = socket.assigns

    service_params
    |> Map.put("barber_shop_id", barber.barber_shop.id)
    |> BarberService.create()
    |> case do
      {:ok, service} ->
        socket =
          socket
          |> assign(:services, service)
          |> put_flash(:info, "Service Created successfuly")
          |> push_navigate(to: ~p"/barber/dashboard")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end
end
