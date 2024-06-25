defmodule Barbertime.BarberService do
  import Ecto.Query
  alias Barbertime.Repo
  alias Barbertime.BarberShop.Service

  @doc """
  Receive a map to register a service on the database
  ## Examples
      iex> Barbertime.BarberService.create(
          %{
          name: "Hair",
          price: 11.59,
          duration: 30,
          barber_shop_id: "0248ae1e-526a-4c2c-b611-bd320a119b08"}
           )
  """
  @spec create(map()) :: {:ok, Service.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    attrs
    |> Service.changeset()
    |> Repo.insert()
  end

  @doc """
  Receive a id shop to lsit all services from the database
  ## Examples
      iex> Barbertime.BarberService.list_all(
           "12584a00-7074-45b1-b9e2-1c0aadec1616"
           )
  """
  @spec list_all(Binary.t()) :: List.t() | nil
  def list_all(barber_shop_id) do
    Service
    |> from()
    |> where([se], se.barber_shop_id == ^barber_shop_id)
    |> Repo.all()
  end

  @doc """
  Receive a id service to take a services from the database
  ## Examples
      iex> Barbertime.BarberService.by_id(
           "12584a00-7074-45b1-b9e2-1c0aadec1616"
           )
  """
  @spec by_id(Binary.t()) :: {:ok, Service.t()} | nil
  def by_id(service_id), do: {:ok, Repo.get(Service, service_id)}

  @doc """
  Receive a id service to update a service on the database
  ## Examples
      iex> Barbertime.BarberService.update(
          %{
          id: Ecto.UUID.autogenerate()
           )
  """
  @spec update(Ecto.UUID.t(), map()) :: {:ok, Service.t()} | {:error, Ecto.Changeset.t()}
  def update(id, attrs) do
    Service
    |> Repo.get(id)
    |> Service.changeset(attrs)
    |> Repo.update()
  end
end
