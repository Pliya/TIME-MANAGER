defmodule Time_manager.WorkDurationTest do
  use Time_manager.DataCase

  alias Time_manager.WorkDuration
  alias Time_manager.WorkDuration.WorkingTime

  import Time_manager.AccountFixtures
  import Time_manager.WorkDurationFixtures

  describe "workingtime" do
    setup do
      %{user: user_fixture()}
    end

    test "list_working_times_for_user/2 returns only the user's entries", %{user: user} do
      working_time = working_time_fixture(user.id)
      working_time_fixture(user_fixture().id)

      assert WorkDuration.list_working_times_for_user(user.id) == [working_time]
    end

    test "list_working_times_for_user/2 filters by start and end", %{user: user} do
      day1 = working_time_fixture(user.id)

      day2 =
        working_time_fixture(user.id, %{
          start: ~U[2026-09-22 08:00:00Z],
          end: ~U[2026-09-22 17:00:00Z]
        })

      assert WorkDuration.list_working_times_for_user(user.id, %{
               "start" => "2026-09-22T00:00:00Z"
             }) == [day2]

      assert WorkDuration.list_working_times_for_user(user.id, %{
               "end" => "2026-09-21T23:59:59Z"
             }) == [day1]
    end

    test "get_working_time_for_user/2 checks the owner", %{user: user} do
      working_time = working_time_fixture(user.id)
      assert WorkDuration.get_working_time_for_user(user.id, working_time.id) == working_time
      assert WorkDuration.get_working_time_for_user(user_fixture().id, working_time.id) == nil
    end

    test "create_working_time/1 with valid data creates a working_time", %{user: user} do
      attrs = %{start: "2026-09-21T08:00:00Z", end: "2026-09-21T17:00:00Z", user_id: user.id}

      assert {:ok, %WorkingTime{} = working_time} = WorkDuration.create_working_time(attrs)
      assert working_time.start == ~U[2026-09-21 08:00:00Z]
      assert working_time.end == ~U[2026-09-21 17:00:00Z]
    end

    test "create_working_time/1 requires all fields" do
      assert {:error, %Ecto.Changeset{}} =
               WorkDuration.create_working_time(%{start: nil, end: nil})
    end

    test "create_working_time/1 rejects end before start", %{user: user} do
      attrs = %{start: ~U[2026-09-21 17:00:00Z], end: ~U[2026-09-21 08:00:00Z], user_id: user.id}

      assert {:error, changeset} = WorkDuration.create_working_time(attrs)
      assert %{end: ["must be after start"]} = errors_on(changeset)
    end

    test "create_working_time/1 rejects an unknown user" do
      attrs = %{start: ~U[2026-09-21 08:00:00Z], end: ~U[2026-09-21 17:00:00Z], user_id: -1}
      assert {:error, changeset} = WorkDuration.create_working_time(attrs)
      assert %{user_id: ["does not exist"]} = errors_on(changeset)
    end

    test "update_working_time/2 with valid data updates the working_time", %{user: user} do
      working_time = working_time_fixture(user.id)

      assert {:ok, %WorkingTime{} = working_time} =
               WorkDuration.update_working_time(working_time, %{end: ~U[2026-09-21 18:00:00Z]})

      assert working_time.end == ~U[2026-09-21 18:00:00Z]
    end

    test "delete_working_time/1 deletes the working_time", %{user: user} do
      working_time = working_time_fixture(user.id)
      assert {:ok, %WorkingTime{}} = WorkDuration.delete_working_time(working_time)
      assert WorkDuration.get_working_time(working_time.id) == nil
    end
  end
end
