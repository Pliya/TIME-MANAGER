defmodule Time_manager.AttendanceFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Time_manager.Attendance` context.
  """

  @doc """
  Generate a clock for the given user (toggles in/out like the API).
  """
  def clock_fixture(user_id) do
    {:ok, clock} = Time_manager.Attendance.create_clock(user_id)
    clock
  end
end
