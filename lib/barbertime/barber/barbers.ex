defmodule Barbertime.Barber.Barbers do
  import Ecto.Query

  alias Barbertime.Barber
  alias Barbertime.Repo
  alias Barbertime.Barber.Schema.Barber

  @doc """
  Receive a map to register a barber on the database
  ## Examples
      iex> Barbertime.Barber.Barbers.create( %{
          first_name: "Barber",
          last_name: "Cutter",
          email: "barbercutter@mail.com",
          password: "Barbercutter@123",
          confirmed_at: NaiveDateTime.local_now()
           })
  """
  @spec create(map()) :: {:ok, Barber.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    attrs
    |> Barber.changeset()
    |> Repo.insert()
  end

  @spec create_changeset(map()) :: Ecto.Changeset.t() | {:error, Ecto.Changeset.t()}
  def create_changeset(barber) do
    barber
    |> Barber.changeset()
  end

  @doc """
  Gets a barber by email.

  ## Examples

      iex> Barbertime.Barber.Barbers.get_barber_by_email("foo@example.com")
      %barber{}

      iex> Barbertime.Barber.Barbers.get_barber_by_email("unknown@example.com")
      nil

  """
  def get_barber_by_email(email) when is_binary(email) do
    Repo.get_by(Barber, email: email)
  end

  @doc """
  Gets a barber by email and password.

  ## Examples

      iex> Barbertime.Barber.Barbers.get_barber_by_email_and_password("foo@example.com", "correct_password")
      %Barber{}

      iex> Barbertime.Barber.Barbers.get_barber_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_barber_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    barber = Repo.get_by(Barber, email: email)
    if Barber.valid_password?(barber, password), do: barber
  end

  @doc """
  Resets the barber password.

  ## Examples

      iex> Barbertime.Barber.Barbers.reset_barber_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> Barbertime.Barber.Barbers.reset_barber_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(barber, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:barber, Barber.password_changeset(barber, attrs))
    |> Repo.transaction()
    |> case do
      {:ok, %{barber: barber}} -> {:ok, barber}
      {:error, :barber, changeset, _} -> {:error, changeset}
    end
  end
end
