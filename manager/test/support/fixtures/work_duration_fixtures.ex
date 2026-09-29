defmodule Time_manager.WorkDurationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Time_manager.WorkDuration` context.
  """

  @doc """
  Generate a working_time for the given user.
  """
  def working_time_fixture(user_id, attrs \\ %{}) do
    {:ok, working_time} =
      attrs
      |> Enum.into(%{
        start: ~U[2026-09-21 08:00:00Z],
        end: ~U[2026-09-21 17:00:00Z],
        user_id: user_id
      })
      |> Time_manager.WorkDuration.create_working_time()

    working_time
  end
end
