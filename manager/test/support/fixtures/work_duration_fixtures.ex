defmodule Time_manager.WorkDurationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Time_manager.WorkDuration` context.
  """

  @doc """
  Generate a working_time.
  """
  def working_time_fixture(attrs \\ %{}) do
    {:ok, working_time} =
      attrs
      |> Enum.into(%{
        end: ~N[2026-09-21 08:33:00],
        start: ~N[2026-09-21 08:33:00]
      })
      |> Time_manager.WorkDuration.create_working_time()

    working_time
  end
end
