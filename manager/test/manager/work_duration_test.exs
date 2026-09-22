defmodule Time_manager.WorkDurationTest do
  use Time_manager.DataCase

  alias Time_manager.WorkDuration

  describe "workingtime" do
    alias Time_manager.WorkDuration.WorkingTime

    import Time_manager.WorkDurationFixtures

    @invalid_attrs %{start: nil, end: nil}

    test "list_workingtime/0 returns all workingtime" do
      working_time = working_time_fixture()
      assert WorkDuration.list_workingtime() == [working_time]
    end

    test "get_working_time!/1 returns the working_time with given id" do
      working_time = working_time_fixture()
      assert WorkDuration.get_working_time!(working_time.id) == working_time
    end

    test "create_working_time/1 with valid data creates a working_time" do
      valid_attrs = %{start: ~N[2026-09-21 08:33:00], end: ~N[2026-09-21 08:33:00]}

      assert {:ok, %WorkingTime{} = working_time} = WorkDuration.create_working_time(valid_attrs)
      assert working_time.start == ~N[2026-09-21 08:33:00]
      assert working_time.end == ~N[2026-09-21 08:33:00]
    end

    test "create_working_time/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = WorkDuration.create_working_time(@invalid_attrs)
    end

    test "update_working_time/2 with valid data updates the working_time" do
      working_time = working_time_fixture()
      update_attrs = %{start: ~N[2026-09-22 08:33:00], end: ~N[2026-09-22 08:33:00]}

      assert {:ok, %WorkingTime{} = working_time} = WorkDuration.update_working_time(working_time, update_attrs)
      assert working_time.start == ~N[2026-09-22 08:33:00]
      assert working_time.end == ~N[2026-09-22 08:33:00]
    end

    test "update_working_time/2 with invalid data returns error changeset" do
      working_time = working_time_fixture()
      assert {:error, %Ecto.Changeset{}} = WorkDuration.update_working_time(working_time, @invalid_attrs)
      assert working_time == WorkDuration.get_working_time!(working_time.id)
    end

    test "delete_working_time/1 deletes the working_time" do
      working_time = working_time_fixture()
      assert {:ok, %WorkingTime{}} = WorkDuration.delete_working_time(working_time)
      assert_raise Ecto.NoResultsError, fn -> WorkDuration.get_working_time!(working_time.id) end
    end

    test "change_working_time/1 returns a working_time changeset" do
      working_time = working_time_fixture()
      assert %Ecto.Changeset{} = WorkDuration.change_working_time(working_time)
    end
  end
end
