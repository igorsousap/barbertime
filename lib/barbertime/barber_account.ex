defmodule Barbertime.BarberAccount do
  @moduledoc """
  The BarberAccount context.
  """

  import Ecto.Query, warn: false
  alias Barbertime.Repo

  alias Barbertime.BarberAccount.{Barber, BarberToken, BarberNotifier}

  ## Database getters

  @doc """
  Gets a barber by email.

  ## Examples

      iex> get_barber_by_email("foo@example.com")
      %Barber{}

      iex> get_barber_by_email("unknown@example.com")
      nil

  """
  def get_barber_by_email(email) when is_binary(email) do
    Repo.get_by(Barber, email: email)
  end

  @doc """
  Gets a barber by email and password.

  ## Examples

      iex> get_barber_by_email_and_password("foo@example.com", "correct_password")
      %Barber{}

      iex> get_barber_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_barber_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    barber = Repo.get_by(Barber, email: email)
    if Barber.valid_password?(barber, password), do: barber
  end

  @doc """
  Gets a single barber.

  Raises `Ecto.NoResultsError` if the Barber does not exist.

  ## Examples

      iex> get_barber!(123)
      %Barber{}

      iex> get_barber!(456)
      ** (Ecto.NoResultsError)

  """
  def get_barber!(id), do: Repo.get!(Barber, id)

  ## Barber registration

  @doc """
  Registers a barber.
  Receive a map to register a barber on the database
  ## Examples
      iex> Barbertime.BarberAccount.register_barber( %{
          first_name: "Barber",
          last_name: "Cutter",
          email: "barbercutter@mail.com",
          password: "Barbercutter@123",
          confirmed_at: NaiveDateTime.local_now()
           })
  """
  def register_barber(attrs) do
    %Barber{}
    |> Barber.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking barber changes.

  ## Examples

      iex> change_barber_registration(barber)
      %Ecto.Changeset{data: %Barber{}}

  """
  def change_barber_registration(%Barber{} = barber, attrs \\ %{}) do
    Barber.registration_changeset(barber, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the barber email.

  ## Examples

      iex> change_barber_email(barber)
      %Ecto.Changeset{data: %Barber{}}

  """
  def change_barber_email(barber, attrs \\ %{}) do
    Barber.email_changeset(barber, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_barber_email(barber, "valid password", %{email: ...})
      {:ok, %Barber{}}

      iex> apply_barber_email(barber, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_barber_email(barber, password, attrs) do
    barber
    |> Barber.email_changeset(attrs)
    |> Barber.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the barber email using the given token.

  If the token matches, the barber email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_barber_email(barber, token) do
    context = "change:#{barber.email}"

    with {:ok, query} <- BarberToken.verify_change_email_token_query(token, context),
         %BarberToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(barber_email_multi(barber, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp barber_email_multi(barber, email, context) do
    changeset =
      barber
      |> Barber.email_changeset(%{email: email})
      |> Barber.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:barber, changeset)
    |> Ecto.Multi.delete_all(:tokens, BarberToken.by_barber_and_contexts_query(barber, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given barber.

  ## Examples

      iex> deliver_barber_update_email_instructions(barber, current_email, &url(~p"/barbers/settings/confirm_email/#{&1})")
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_barber_update_email_instructions(
        %Barber{} = barber,
        current_email,
        update_email_url_fun
      )
      when is_function(update_email_url_fun, 1) do
    {encoded_token, barber_token} =
      BarberToken.build_email_token(barber, "change:#{current_email}")

    Repo.insert!(barber_token)
    BarberNotifier.deliver_update_email_instructions(barber, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the barber password.

  ## Examples

      iex> change_barber_password(barber)
      %Ecto.Changeset{data: %Barber{}}

  """
  def change_barber_password(barber, attrs \\ %{}) do
    Barber.password_changeset(barber, attrs, hash_password: false)
  end

  @doc """
  Updates the barber password.

  ## Examples

      iex> update_barber_password(barber, "valid password", %{password: ...})
      {:ok, %Barber{}}

      iex> update_barber_password(barber, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_barber_password(barber, password, attrs) do
    changeset =
      barber
      |> Barber.password_changeset(attrs)
      |> Barber.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:barber, changeset)
    |> Ecto.Multi.delete_all(:tokens, BarberToken.by_barber_and_contexts_query(barber, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{barber: barber}} -> {:ok, barber}
      {:error, :barber, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_barber_session_token(barber) do
    {token, barber_token} = BarberToken.build_session_token(barber)
    Repo.insert!(barber_token)
    token
  end

  @doc """
  Gets the barber with the given signed token.
  """
  def get_barber_by_session_token(token) do
    {:ok, query} = BarberToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_barber_session_token(token) do
    Repo.delete_all(BarberToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given barber.

  ## Examples

      iex> deliver_barber_confirmation_instructions(barber, &url(~p"/barbers/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_barber_confirmation_instructions(confirmed_barber, &url(~p"/barbers/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_barber_confirmation_instructions(%Barber{} = barber, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if barber.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, barber_token} = BarberToken.build_email_token(barber, "confirm")
      Repo.insert!(barber_token)

      BarberNotifier.deliver_confirmation_instructions(
        barber,
        confirmation_url_fun.(encoded_token)
      )
    end
  end

  @doc """
  Confirms a barber by the given token.

  If the token matches, the barber account is marked as confirmed
  and the token is deleted.
  """
  def confirm_barber(token) do
    with {:ok, query} <- BarberToken.verify_email_token_query(token, "confirm"),
         %Barber{} = barber <- Repo.one(query),
         {:ok, %{barber: barber}} <- Repo.transaction(confirm_barber_multi(barber)) do
      {:ok, barber}
    else
      _ -> :error
    end
  end

  defp confirm_barber_multi(barber) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:barber, Barber.confirm_changeset(barber))
    |> Ecto.Multi.delete_all(
      :tokens,
      BarberToken.by_barber_and_contexts_query(barber, ["confirm"])
    )
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given barber.

  ## Examples

      iex> deliver_barber_reset_password_instructions(barber, &url(~p"/barbers/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_barber_reset_password_instructions(%Barber{} = barber, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, barber_token} = BarberToken.build_email_token(barber, "reset_password")
    Repo.insert!(barber_token)

    BarberNotifier.deliver_reset_password_instructions(
      barber,
      reset_password_url_fun.(encoded_token)
    )
  end

  @doc """
  Gets the barber by reset password token.

  ## Examples

      iex> get_barber_by_reset_password_token("validtoken")
      %Barber{}

      iex> get_barber_by_reset_password_token("invalidtoken")
      nil

  """
  def get_barber_by_reset_password_token(token) do
    with {:ok, query} <- BarberToken.verify_email_token_query(token, "reset_password"),
         %Barber{} = barber <- Repo.one(query) do
      barber
    else
      _ -> nil
    end
  end

  @doc """
  Resets the barber password.

  ## Examples

      iex> reset_barber_password(barber, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Barber{}}

      iex> reset_barber_password(barber, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_barber_password(barber, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:barber, Barber.password_changeset(barber, attrs))
    |> Ecto.Multi.delete_all(:tokens, BarberToken.by_barber_and_contexts_query(barber, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{barber: barber}} -> {:ok, barber}
      {:error, :barber, changeset, _} -> {:error, changeset}
    end
  end
end
