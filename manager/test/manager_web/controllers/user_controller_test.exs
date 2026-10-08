defmodule Time_managerWeb.UserControllerTest do
  use Time_managerWeb.ConnCase

  import Time_manager.AccountFixtures

  alias Time_manager.Account.User

  @create_attrs %{username: "some username", email: "some@email.com"}
  @update_attrs %{username: "some updated username", email: "updated@email.com"}
  @invalid_attrs %{username: nil, email: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all users", %{conn: conn} do
      conn = get(again(conn), ~p"/api/users")
      assert json_response(conn, 200)["data"] == []
    end

    test "filters by email and username", %{conn: conn} do
      user = user_fixture(%{username: "alice"})
      user_fixture(%{username: "bob"})

      conn = get(again(conn), ~p"/api/users?#{[email: user.email, username: "alice"]}")
      assert [%{"id" => id}] = json_response(conn, 200)["data"]
      assert id == user.id
    end
  end

  describe "create user" do
    test "renders user when data is valid", %{conn: conn} do
      conn = post(again(conn), ~p"/api/users", user: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(again(conn), ~p"/api/users/#{id}")

      assert %{
               "id" => ^id,
               "email" => "some@email.com",
               "username" => "some username"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(again(conn), ~p"/api/users", user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "show user" do
    test "renders 404 when the user does not exist", %{conn: conn} do
      conn = get(again(conn), ~p"/api/users/-1")
      assert json_response(conn, 404)
    end
  end

  describe "update user" do
    setup [:create_user]

    test "renders user when data is valid", %{conn: conn, user: %User{id: id} = user} do
      conn = put(again(conn), ~p"/api/users/#{user}", user: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(again(conn), ~p"/api/users/#{id}")

      assert %{
               "id" => ^id,
               "email" => "updated@email.com",
               "username" => "some updated username"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put(again(conn), ~p"/api/users/#{user}", user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete user" do
    setup [:create_user]

    test "deletes chosen user", %{conn: conn, user: user} do
      conn = delete(again(conn), ~p"/api/users/#{user}")
      assert response(conn, 204)

      conn = get(again(conn), ~p"/api/users/#{user}")
      assert json_response(conn, 404)
    end

    test "deletes a user that has clocks and working times", %{conn: conn, user: user} do
      Time_manager.AttendanceFixtures.clock_fixture(user.id)
      Time_manager.WorkDurationFixtures.working_time_fixture(user.id)

      conn = delete(again(conn), ~p"/api/users/#{user}")
      assert response(conn, 204)
    end
  end

  defp create_user(_) do
    %{user: user_fixture()}
  end
end
