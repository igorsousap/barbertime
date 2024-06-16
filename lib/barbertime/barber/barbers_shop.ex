defmodule Barbertime.Barber.BarbersShop do
  alias Barbertime.Repo
  alias Barbertime.Barber.Schema.BarberShop

  @doc """
  Receive a map to register a barber shop on the database
  ## Examples
      iex> Barbertime.Barber.BarbersShop.create( %{
          name_store: "Test Store",
          adress: "Street Test",
          number: 99,
          cep: "62010-140",
          cnpj: Brcpfcnpj.cnpj_generate(),
          phone: "88999999999",
          barber_id: "e8c672c1-87cd-4412-9e84-8c425327e315"
           })
  """
  @spec create(map()) :: {:ok, BarberShop.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    attrs
    |> BarberShop.changeset()
    |> Repo.insert()
  end

  @doc """
  Receive a Barber shop to create a changeset
  ## Examples
      iex> Barbertime.Barber.BarbersShop.create_changeset(%BarberShop{
          name_store: "Test Store",
          adress: "Street Test",
          number: 99,
          cep: "62010-140",
          cnpj: Brcpfcnpj.cnpj_generate(),
          phone: "88999999999",
          barber_id: Ecto.UUID.autogenerate())
  """

  @spec create_changeset(BarberShop.t(), map()) ::
          Ecto.Changeset.t() | {:error, Ecto.Changeset.t()}
  def create_changeset(%BarberShop{} = barber, attrs \\ %{}) do
    barber
    |> BarberShop.changeset(attrs)
  end

  @doc """
  Gets a barber shop by barber_id.

  ## Examples

      iex> Barbertime.Barber.BarbersShop.get_barbershop_by_barber_id(Ecto.UUID.autogenerate())
      %barber{}

      iex> Barbertime.Barber.BarbersShop.get_barbershop_by_barber_id("unknown_barber_id")
      nil

  """
  def get_barbershop_by_barber_id(barber_id) when is_binary(barber_id) do
    Repo.get_by(BarberShop, barber_id: barber_id)
  end

  @doc """
  Gets a all barber shop by barber_id.

  ## Examples

      iex> Barbertime.Barber.BarbersShop.get_all_barbershop_by_barber_id(Ecto.UUID.autogenerate())
      %barber{}

      iex> Barbertime.Barber.BarbersShop.get_all_barbershop_by_barber_id("unknown_barber_id")
      nil

  """
  def get_all_barbershop_by_barber_id(barber_id) when is_binary(barber_id) do
    Repo.all(BarberShop, barber_id: barber_id)
  end
end
