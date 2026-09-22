defmodule Time_manager.AttendanceFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Time_manager.Attendance` context.
  """

  @doc """
  Generate a clock.
  """
  def clock_fixture(attrs \\ %{}) do
    {:ok, clock} =
      attrs
      |> Enum.into(%{
        status: true,
        time: ~U[2026-09-21 08:32:00Z]
      })
      |> Time_manager.Attendance.create_clock()

    clock
  end
end
