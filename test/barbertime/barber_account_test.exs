defmodule Barbertime.BarberAccountTest do
  use Barbertime.DataCase

  alias Barbertime.BarberAccount

  import Barbertime.BarberAccountFixtures
  alias Barbertime.BarberAccount.{Barber, BarberToken}

  describe "get_barber_by_email/1" do
    test "does not return the barber if the email does not exist" do
      refute BarberAccount.get_barber_by_email("unknown@example.com")
    end

    test "returns the barber if the email exists" do
      %{id: id} = barber = barber_fixture()
      assert %Barber{id: ^id} = BarberAccount.get_barber_by_email(barber.email)
    end
  end

  describe "get_barber_by_email_and_password/2" do
    test "does not return the barber if the email does not exist" do
      refute BarberAccount.get_barber_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the barber if the password is not valid" do
      barber = barber_fixture()
      refute BarberAccount.get_barber_by_email_and_password(barber.email, "invalid")
    end

    test "returns the barber if the email and password are valid" do
      %{id: id} = barber = barber_fixture()

      assert %Barber{id: ^id} =
               BarberAccount.get_barber_by_email_and_password(barber.email, valid_barber_password())
    end
  end

  describe "get_barber!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        BarberAccount.get_barber!(-1)
      end
    end

    test "returns the barber with the given id" do
      %{id: id} = barber = barber_fixture()
      assert %Barber{id: ^id} = BarberAccount.get_barber!(barber.id)
    end
  end

  describe "register_barber/1" do
    test "requires email and password to be set" do
      {:error, changeset} = BarberAccount.register_barber(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = BarberAccount.register_barber(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = BarberAccount.register_barber(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = barber_fixture()
      {:error, changeset} = BarberAccount.register_barber(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = BarberAccount.register_barber(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers barbers with a hashed password" do
      email = unique_barber_email()
      {:ok, barber} = BarberAccount.register_barber(valid_barber_attributes(email: email))
      assert barber.email == email
      assert is_binary(barber.hashed_password)
      assert is_nil(barber.confirmed_at)
      assert is_nil(barber.password)
    end
  end

  describe "change_barber_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = BarberAccount.change_barber_registration(%Barber{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_barber_email()
      password = valid_barber_password()

      changeset =
        BarberAccount.change_barber_registration(
          %Barber{},
          valid_barber_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_barber_email/2" do
    test "returns a barber changeset" do
      assert %Ecto.Changeset{} = changeset = BarberAccount.change_barber_email(%Barber{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_barber_email/3" do
    setup do
      %{barber: barber_fixture()}
    end

    test "requires email to change", %{barber: barber} do
      {:error, changeset} = BarberAccount.apply_barber_email(barber, valid_barber_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{barber: barber} do
      {:error, changeset} =
        BarberAccount.apply_barber_email(barber, valid_barber_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{barber: barber} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        BarberAccount.apply_barber_email(barber, valid_barber_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{barber: barber} do
      %{email: email} = barber_fixture()
      password = valid_barber_password()

      {:error, changeset} = BarberAccount.apply_barber_email(barber, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{barber: barber} do
      {:error, changeset} =
        BarberAccount.apply_barber_email(barber, "invalid", %{email: unique_barber_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{barber: barber} do
      email = unique_barber_email()
      {:ok, barber} = BarberAccount.apply_barber_email(barber, valid_barber_password(), %{email: email})
      assert barber.email == email
      assert BarberAccount.get_barber!(barber.id).email != email
    end
  end

  describe "deliver_barber_update_email_instructions/3" do
    setup do
      %{barber: barber_fixture()}
    end

    test "sends token through notification", %{barber: barber} do
      token =
        extract_barber_token(fn url ->
          BarberAccount.deliver_barber_update_email_instructions(barber, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert barber_token = Repo.get_by(BarberToken, token: :crypto.hash(:sha256, token))
      assert barber_token.barber_id == barber.id
      assert barber_token.sent_to == barber.email
      assert barber_token.context == "change:current@example.com"
    end
  end

  describe "update_barber_email/2" do
    setup do
      barber = barber_fixture()
      email = unique_barber_email()

      token =
        extract_barber_token(fn url ->
          BarberAccount.deliver_barber_update_email_instructions(%{barber | email: email}, barber.email, url)
        end)

      %{barber: barber, token: token, email: email}
    end

    test "updates the email with a valid token", %{barber: barber, token: token, email: email} do
      assert BarberAccount.update_barber_email(barber, token) == :ok
      changed_barber = Repo.get!(Barber, barber.id)
      assert changed_barber.email != barber.email
      assert changed_barber.email == email
      assert changed_barber.confirmed_at
      assert changed_barber.confirmed_at != barber.confirmed_at
      refute Repo.get_by(BarberToken, barber_id: barber.id)
    end

    test "does not update email with invalid token", %{barber: barber} do
      assert BarberAccount.update_barber_email(barber, "oops") == :error
      assert Repo.get!(Barber, barber.id).email == barber.email
      assert Repo.get_by(BarberToken, barber_id: barber.id)
    end

    test "does not update email if barber email changed", %{barber: barber, token: token} do
      assert BarberAccount.update_barber_email(%{barber | email: "current@example.com"}, token) == :error
      assert Repo.get!(Barber, barber.id).email == barber.email
      assert Repo.get_by(BarberToken, barber_id: barber.id)
    end

    test "does not update email if token expired", %{barber: barber, token: token} do
      {1, nil} = Repo.update_all(BarberToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert BarberAccount.update_barber_email(barber, token) == :error
      assert Repo.get!(Barber, barber.id).email == barber.email
      assert Repo.get_by(BarberToken, barber_id: barber.id)
    end
  end

  describe "change_barber_password/2" do
    test "returns a barber changeset" do
      assert %Ecto.Changeset{} = changeset = BarberAccount.change_barber_password(%Barber{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        BarberAccount.change_barber_password(%Barber{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_barber_password/3" do
    setup do
      %{barber: barber_fixture()}
    end

    test "validates password", %{barber: barber} do
      {:error, changeset} =
        BarberAccount.update_barber_password(barber, valid_barber_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{barber: barber} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        BarberAccount.update_barber_password(barber, valid_barber_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{barber: barber} do
      {:error, changeset} =
        BarberAccount.update_barber_password(barber, "invalid", %{password: valid_barber_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{barber: barber} do
      {:ok, barber} =
        BarberAccount.update_barber_password(barber, valid_barber_password(), %{
          password: "new valid password"
        })

      assert is_nil(barber.password)
      assert BarberAccount.get_barber_by_email_and_password(barber.email, "new valid password")
    end

    test "deletes all tokens for the given barber", %{barber: barber} do
      _ = BarberAccount.generate_barber_session_token(barber)

      {:ok, _} =
        BarberAccount.update_barber_password(barber, valid_barber_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(BarberToken, barber_id: barber.id)
    end
  end

  describe "generate_barber_session_token/1" do
    setup do
      %{barber: barber_fixture()}
    end

    test "generates a token", %{barber: barber} do
      token = BarberAccount.generate_barber_session_token(barber)
      assert barber_token = Repo.get_by(BarberToken, token: token)
      assert barber_token.context == "session"

      # Creating the same token for another barber should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%BarberToken{
          token: barber_token.token,
          barber_id: barber_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_barber_by_session_token/1" do
    setup do
      barber = barber_fixture()
      token = BarberAccount.generate_barber_session_token(barber)
      %{barber: barber, token: token}
    end

    test "returns barber by token", %{barber: barber, token: token} do
      assert session_barber = BarberAccount.get_barber_by_session_token(token)
      assert session_barber.id == barber.id
    end

    test "does not return barber for invalid token" do
      refute BarberAccount.get_barber_by_session_token("oops")
    end

    test "does not return barber for expired token", %{token: token} do
      {1, nil} = Repo.update_all(BarberToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute BarberAccount.get_barber_by_session_token(token)
    end
  end

  describe "delete_barber_session_token/1" do
    test "deletes the token" do
      barber = barber_fixture()
      token = BarberAccount.generate_barber_session_token(barber)
      assert BarberAccount.delete_barber_session_token(token) == :ok
      refute BarberAccount.get_barber_by_session_token(token)
    end
  end

  describe "deliver_barber_confirmation_instructions/2" do
    setup do
      %{barber: barber_fixture()}
    end

    test "sends token through notification", %{barber: barber} do
      token =
        extract_barber_token(fn url ->
          BarberAccount.deliver_barber_confirmation_instructions(barber, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert barber_token = Repo.get_by(BarberToken, token: :crypto.hash(:sha256, token))
      assert barber_token.barber_id == barber.id
      assert barber_token.sent_to == barber.email
      assert barber_token.context == "confirm"
    end
  end

  describe "confirm_barber/1" do
    setup do
      barber = barber_fixture()

      token =
        extract_barber_token(fn url ->
          BarberAccount.deliver_barber_confirmation_instructions(barber, url)
        end)

      %{barber: barber, token: token}
    end

    test "confirms the email with a valid token", %{barber: barber, token: token} do
      assert {:ok, confirmed_barber} = BarberAccount.confirm_barber(token)
      assert confirmed_barber.confirmed_at
      assert confirmed_barber.confirmed_at != barber.confirmed_at
      assert Repo.get!(Barber, barber.id).confirmed_at
      refute Repo.get_by(BarberToken, barber_id: barber.id)
    end

    test "does not confirm with invalid token", %{barber: barber} do
      assert BarberAccount.confirm_barber("oops") == :error
      refute Repo.get!(Barber, barber.id).confirmed_at
      assert Repo.get_by(BarberToken, barber_id: barber.id)
    end

    test "does not confirm email if token expired", %{barber: barber, token: token} do
      {1, nil} = Repo.update_all(BarberToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert BarberAccount.confirm_barber(token) == :error
      refute Repo.get!(Barber, barber.id).confirmed_at
      assert Repo.get_by(BarberToken, barber_id: barber.id)
    end
  end

  describe "deliver_barber_reset_password_instructions/2" do
    setup do
      %{barber: barber_fixture()}
    end

    test "sends token through notification", %{barber: barber} do
      token =
        extract_barber_token(fn url ->
          BarberAccount.deliver_barber_reset_password_instructions(barber, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert barber_token = Repo.get_by(BarberToken, token: :crypto.hash(:sha256, token))
      assert barber_token.barber_id == barber.id
      assert barber_token.sent_to == barber.email
      assert barber_token.context == "reset_password"
    end
  end

  describe "get_barber_by_reset_password_token/1" do
    setup do
      barber = barber_fixture()

      token =
        extract_barber_token(fn url ->
          BarberAccount.deliver_barber_reset_password_instructions(barber, url)
        end)

      %{barber: barber, token: token}
    end

    test "returns the barber with valid token", %{barber: %{id: id}, token: token} do
      assert %Barber{id: ^id} = BarberAccount.get_barber_by_reset_password_token(token)
      assert Repo.get_by(BarberToken, barber_id: id)
    end

    test "does not return the barber with invalid token", %{barber: barber} do
      refute BarberAccount.get_barber_by_reset_password_token("oops")
      assert Repo.get_by(BarberToken, barber_id: barber.id)
    end

    test "does not return the barber if token expired", %{barber: barber, token: token} do
      {1, nil} = Repo.update_all(BarberToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute BarberAccount.get_barber_by_reset_password_token(token)
      assert Repo.get_by(BarberToken, barber_id: barber.id)
    end
  end

  describe "reset_barber_password/2" do
    setup do
      %{barber: barber_fixture()}
    end

    test "validates password", %{barber: barber} do
      {:error, changeset} =
        BarberAccount.reset_barber_password(barber, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{barber: barber} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = BarberAccount.reset_barber_password(barber, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{barber: barber} do
      {:ok, updated_barber} = BarberAccount.reset_barber_password(barber, %{password: "new valid password"})
      assert is_nil(updated_barber.password)
      assert BarberAccount.get_barber_by_email_and_password(barber.email, "new valid password")
    end

    test "deletes all tokens for the given barber", %{barber: barber} do
      _ = BarberAccount.generate_barber_session_token(barber)
      {:ok, _} = BarberAccount.reset_barber_password(barber, %{password: "new valid password"})
      refute Repo.get_by(BarberToken, barber_id: barber.id)
    end
  end

  describe "inspect/2 for the Barber module" do
    test "does not include password" do
      refute inspect(%Barber{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
