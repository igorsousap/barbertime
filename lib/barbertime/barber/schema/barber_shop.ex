defmodule Barbertime.Barber.Schema.BarberShop do
  use Ecto.Schema

  import Ecto.Changeset

  alias Barbertime.Barber.Schema.{Barber, Service}

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          name_store: String.t(),
          adress: String.t(),
          number: Integer.t(),
          cep: String.t(),
          cnpj: String.t(),
          phone: String.t(),
          barber_id: Ecto.UUID.t()
        }

  @fields ~w(name_store adress number cep cnpj phone barber_id)a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "barber_shop" do
    field(:name_store, :string)
    field(:adress, :string)
    field(:number, :integer)
    field(:cep, :string)
    field(:cnpj, :string)
    field(:phone, :string)

    belongs_to(:barber, Barber, type: :binary_id)

    has_many(:services, Service)

    timestamps()
  end

  @doc """
  Receive a barber shop map to create a changeset
  Example
  iex> Barbertime.Barber.Schema.BarberShop.changeset(
          %{
          name_store: "Test Store",
          adress: "Street Test",
          number: 99,
          cep: "62010-140",
          cnpj: Brcpfcnpj.cnpj_generate(),
          phone: "88999999999",
          barber_id: Ecto.UUID.autogenerate()
           })
  """
  @spec changeset(:__MODULE__.t(), map()) :: Ecto.Changeset.t()
  def changeset(barber_shop \\ %__MODULE__{}, attrs) do
    barber_shop
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> unique_constraint([:name_store], name: :barber_shop_name_index)
    |> unique_constraint([:cnpj], name: :barber_shop_cnpj_index)
    |> foreign_key_constraint(:barber_id, name: :barbershop_barber_id_fkey)
    |> validate_cnpj()
    |> validate_format(:cep, ~r/^\d{5}-\d{3}$/, message: "invalid cep")
    |> validate_format(:phone, ~r/^\d{2}\d{4,5}\d{4}$/, message: "invalid phone")
  end

  defp validate_cnpj(changeset),
    do:
      Brcpfcnpj.Changeset.validate_cnpj(changeset, :cnpj,
        message: {"invalid cnpj", [index: :invalid]}
      )
end
