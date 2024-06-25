defmodule Barbertime.BarberAccount.BarberNotifier do
  import Swoosh.Email

  alias Barbertime.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Barbertime", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(barber, url) do
    deliver(barber.email, "Confirmation instructions", """

    ==============================

    Hi #{barber.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a barber password.
  """
  def deliver_reset_password_instructions(barber, url) do
    deliver(barber.email, "Reset password instructions", """

    ==============================

    Hi #{barber.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a barber email.
  """
  def deliver_update_email_instructions(barber, url) do
    deliver(barber.email, "Update email instructions", """

    ==============================

    Hi #{barber.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
