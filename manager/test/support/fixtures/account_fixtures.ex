defmodule Time_manager.AccountFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Time_manager.Account` context.
  """

  def unique_user_email, do: "user#{System.unique_integer([:positive])}@example.com"

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: unique_user_email(),
        username: "some username"
      })
      |> Time_manager.Account.create_user()

    user
  end
end
