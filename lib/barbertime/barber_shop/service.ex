defmodule Barbertime.BarberShop.Service do
  use Ecto.Schema

  import Ecto.Changeset

  alias Barbertime.BarberShop.Shop

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          name: String.t(),
          price: Decimal.t(),
          duration: Integer.t(),
          barber_shop_id: Ecto.UUID.t()
        }

  @fields ~w(name price duration barber_shop_id)a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "services" do
    field(:name, :string)
    field(:price, :decimal)
    field(:duration, :integer)

    belongs_to(:barber_shop, Shop, type: :binary_id)

    timestamps()
  end

  @doc """
  Receive a service map to create a changeset
  Example
  iex> Barbertime.Barber.Schema.Service.changeset(
          %{
          name: "Hair",
          price: 11.59,
          duration: 30,
          barber_shop_id: Ecto.UUID.autogenerate()
           })
  """

  @spec changeset(:__MODULE__.t(), map()) :: Ecto.Changeset.t()
  def changeset(service \\ %__MODULE__{}, attrs) do
    service
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> validate_price()
    |> validate_duration()
    |> foreign_key_constraint(:barber_shop_id, name: :services_barber_shop_id_fkey)
    |> assoc_constraint(:barber_shop)
  end

  defp validate_price(changeset) do
    validate_number(changeset, :price,
      greater_than_or_equal_to: 1,
      message: "must be greater than or equal to one"
    )
  end

  defp validate_duration(changeset) do
    validate_number(changeset, :duration,
      greater_than_or_equal_to: 1,
      message: "must be greater than or equal to one"
    )
  end
end
