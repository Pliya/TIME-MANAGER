defmodule Time_manager.AttendanceTest do
  use Time_manager.DataCase

  alias Time_manager.Attendance

  describe "clocks" do
    alias Time_manager.Attendance.Clock

    import Time_manager.AttendanceFixtures

    @invalid_attrs %{status: nil, time: nil}

    test "list_clocks/0 returns all clocks" do
      clock = clock_fixture()
      assert Attendance.list_clocks() == [clock]
    end

    test "get_clock!/1 returns the clock with given id" do
      clock = clock_fixture()
      assert Attendance.get_clock!(clock.id) == clock
    end

    test "create_clock/1 with valid data creates a clock" do
      valid_attrs = %{status: true, time: ~U[2026-09-21 08:32:00Z]}

      assert {:ok, %Clock{} = clock} = Attendance.create_clock(valid_attrs)
      assert clock.status == true
      assert clock.time == ~U[2026-09-21 08:32:00Z]
    end

    test "create_clock/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Attendance.create_clock(@invalid_attrs)
    end

    test "update_clock/2 with valid data updates the clock" do
      clock = clock_fixture()
      update_attrs = %{status: false, time: ~U[2026-09-22 08:32:00Z]}

      assert {:ok, %Clock{} = clock} = Attendance.update_clock(clock, update_attrs)
      assert clock.status == false
      assert clock.time == ~U[2026-09-22 08:32:00Z]
    end

    test "update_clock/2 with invalid data returns error changeset" do
      clock = clock_fixture()
      assert {:error, %Ecto.Changeset{}} = Attendance.update_clock(clock, @invalid_attrs)
      assert clock == Attendance.get_clock!(clock.id)
    end

    test "delete_clock/1 deletes the clock" do
      clock = clock_fixture()
      assert {:ok, %Clock{}} = Attendance.delete_clock(clock)
      assert_raise Ecto.NoResultsError, fn -> Attendance.get_clock!(clock.id) end
    end

    test "change_clock/1 returns a clock changeset" do
      clock = clock_fixture()
      assert %Ecto.Changeset{} = Attendance.change_clock(clock)
    end
  end
end
