defmodule Time_manager.AttendanceTest do
  use Time_manager.DataCase

  alias Time_manager.Attendance
  alias Time_manager.Attendance.Clock

  import Time_manager.AccountFixtures
  import Time_manager.AttendanceFixtures

  describe "clocks" do
    setup do
      %{user: user_fixture()}
    end

    test "list_clocks/1 returns only the clocks of the user", %{user: user} do
      clock = clock_fixture(user.id)
      other = user_fixture()
      clock_fixture(other.id)

      assert Attendance.list_clocks(user.id) == [clock]
    end

    test "get_clock!/1 returns the clock with given id", %{user: user} do
      clock = clock_fixture(user.id)
      assert Attendance.get_clock!(clock.id) == clock
    end

    test "create_clock/1 starts with a clock-in", %{user: user} do
      assert {:ok, %Clock{} = clock} = Attendance.create_clock(user.id)
      assert clock.status == true
      assert clock.user_id == user.id
      assert DateTime.diff(DateTime.utc_now(), clock.time) < 5
    end

    test "create_clock/1 toggles between clock-in and clock-out", %{user: user} do
      clock_in_an_hour_ago(user.id)

      assert {:ok, %Clock{status: false}} = Attendance.create_clock(user.id)
    end

    test "clocking in alone does not create a working time", %{user: user} do
      {:ok, _} = Attendance.create_clock(user.id)

      assert Time_manager.WorkDuration.list_working_times_for_user(user.id) == []
    end

    test "clocking out creates a working time from the clock-in to the clock-out", %{user: user} do
      clock_in = clock_in_an_hour_ago(user.id)

      {:ok, clock_out} = Attendance.create_clock(user.id)

      assert [working_time] = Time_manager.WorkDuration.list_working_times_for_user(user.id)
      assert working_time.start == clock_in.time
      assert working_time.end == clock_out.time
    end

    test "update_clock/2 with invalid data returns error changeset", %{user: user} do
      clock = clock_fixture(user.id)
      assert {:error, %Ecto.Changeset{}} = Attendance.update_clock(clock, %{time: nil})
      assert clock == Attendance.get_clock!(clock.id)
    end

    test "delete_clock/1 deletes the clock", %{user: user} do
      clock = clock_fixture(user.id)
      assert {:ok, %Clock{}} = Attendance.delete_clock(clock)
      assert_raise Ecto.NoResultsError, fn -> Attendance.get_clock!(clock.id) end
    end

    test "change_clock/1 returns a clock changeset", %{user: user} do
      clock = clock_fixture(user.id)
      assert %Ecto.Changeset{} = Attendance.change_clock(clock)
    end
  end

  defp clock_in_an_hour_ago(user_id) do
    {:ok, clock} = Attendance.create_clock(user_id)
    {:ok, clock} = Attendance.update_clock(clock, %{time: DateTime.add(clock.time, -3600)})
    clock
  end
end
