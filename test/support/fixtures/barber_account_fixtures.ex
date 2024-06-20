defmodule Barbertime.BarberAccountFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Barbertime.BarberAccount` context.
  """

  def unique_barber_email, do: "barber#{System.unique_integer()}@example.com"
  def valid_barber_password, do: "hello world!"

  def valid_barber_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_barber_email(),
      password: valid_barber_password()
    })
  end

  def barber_fixture(attrs \\ %{}) do
    {:ok, barber} =
      attrs
      |> valid_barber_attributes()
      |> Barbertime.BarberAccount.register_barber()

    barber
  end

  def extract_barber_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
