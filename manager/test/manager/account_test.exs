defmodule Time_manager.AccountTest do
  use Time_manager.DataCase

  alias Time_manager.Account
  alias Time_manager.Account.User

  import Time_manager.AccountFixtures
  import Time_manager.AttendanceFixtures
  import Time_manager.WorkDurationFixtures

  @invalid_attrs %{username: nil, email: nil}

  describe "users" do
    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Enum.map(Account.list_users(), & &1.id) == [user.id]
    end

    test "list_users/1 filters by email and username" do
      user = user_fixture(%{username: "alice"})
      _other = user_fixture(%{username: "bob"})

      assert Enum.map(Account.list_users(%{"email" => user.email}), & &1.id) == [user.id]
      assert Enum.map(Account.list_users(%{"username" => "alice"}), & &1.id) == [user.id]
      assert Account.list_users(%{"email" => user.email, "username" => "bob"}) == []
    end

    test "get_user/1 returns the user or nil" do
      user = user_fixture()
      assert Account.get_user(user.id) == user
      assert Account.get_user(-1) == nil
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} =
               Account.create_user(%{username: "some username", email: "a@b.co"})

      assert user.username == "some username"
      assert user.email == "a@b.co"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Account.create_user(@invalid_attrs)
    end

    test "create_user/1 rejects a malformed email" do
      assert {:error, changeset} = Account.create_user(%{username: "x", email: "not-an-email"})
      assert %{email: [_]} = errors_on(changeset)
    end

    test "create_user/1 rejects a duplicate email" do
      user = user_fixture()
      assert {:error, changeset} = Account.create_user(%{username: "x", email: user.email})
      assert %{email: ["cette adresse email est déjà utilisée"]} = errors_on(changeset)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()

      assert {:ok, %User{} = user} =
               Account.update_user(user, %{username: "updated", email: "updated@b.co"})

      assert user.username == "updated"
      assert user.email == "updated@b.co"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Account.update_user(user, @invalid_attrs)
      assert user == Account.get_user!(user.id)
    end

    test "delete_user/1 deletes the user and its clocks and working times" do
      user = user_fixture()
      clock_fixture(user.id)
      working_time_fixture(user.id)

      assert {:ok, %User{}} = Account.delete_user(user)
      assert Account.get_user(user.id) == nil
      assert Time_manager.Attendance.list_clocks(user.id) == []
      assert Time_manager.WorkDuration.list_working_times_for_user(user.id) == []
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Account.change_user(user)
    end
  end
end
