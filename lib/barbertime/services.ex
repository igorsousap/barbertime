defmodule Barbertime.Barber.Services do
  alias Barbertime.Repo
  alias Barbertime.Barber.Schema.Service

  @doc """
  Receive a map to register a barber shop on the database
  ## Examples
      iex> Barbertime.Barber.Services.create( %{
          name: "Hair",
          price: 11.59,
          duration: 30,
          barber_shop_id: "1dfc7458-af0f-438d-8fe5-ae7272ae1559"
           })
  """
  @spec create(map()) :: {:ok, Service.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    attrs
    |> Service.changeset()
    |> Repo.insert()
  end

  @doc """
  Gets a all barber shop by barber_shop_id.

  ## Examples

      iex> Barbertime.Barber.Services.get_all_services_by_barber_shop_id("1dfc7458-af0f-438d-8fe5-ae7272ae1559")
      %barber{}

      iex> Barbertime.Barber.Services.get_all_services_by_barber_shop_id("unknown_barber_shop_id")
      nil

  """
  def get_all_services_by_barber_shop_id(barber_shop_id) when is_binary(barber_shop_id) do
    Repo.all(Service, barber_shop_id: barber_shop_id)
  end
end
