defmodule Time_managerWeb.WorkingTimeControllerTest do
  use Time_managerWeb.ConnCase

  import Time_manager.AccountFixtures
  import Time_manager.WorkDurationFixtures

  @create_attrs %{start: "2026-09-21T08:00:00Z", end: "2026-09-21T17:00:00Z"}
  @update_attrs %{start: "2026-09-21T09:00:00Z", end: "2026-09-21T18:00:00Z"}
  @invalid_attrs %{start: "2026-09-21T17:00:00Z", end: "2026-09-21T08:00:00Z"}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json"), user: user_fixture()}
  end

  describe "index" do
    test "lists the working times of the user", %{conn: conn, user: user} do
      working_time = working_time_fixture(user.id)
      working_time_fixture(user_fixture().id)

      conn = get(conn, ~p"/api/workingtime/#{user.id}")
      assert [%{"id" => id}] = json_response(conn, 200)["data"]
      assert id == working_time.id
    end

    test "filters by start and end", %{conn: conn, user: user} do
      working_time_fixture(user.id)

      conn = get(conn, ~p"/api/workingtime/#{user.id}?#{[start: "2026-09-22T00:00:00Z"]}")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create working_time" do
    test "renders working_time when data is valid", %{conn: conn, user: user} do
      conn = post(conn, ~p"/api/workingtime/#{user.id}", working_time: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/workingtime/#{user.id}/#{id}")
      user_id = user.id

      assert %{
               "id" => ^id,
               "start" => "2026-09-21T08:00:00Z",
               "end" => "2026-09-21T17:00:00Z",
               "user_id" => ^user_id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when end is before start", %{conn: conn, user: user} do
      conn = post(conn, ~p"/api/workingtime/#{user.id}", working_time: @invalid_attrs)
      assert %{"end" => ["must be after start"]} = json_response(conn, 422)["errors"]
    end
  end

  describe "show working_time" do
    test "renders 404 when the entry belongs to another user", %{conn: conn, user: user} do
      working_time = working_time_fixture(user.id)
      conn = get(conn, ~p"/api/workingtime/#{user_fixture().id}/#{working_time.id}")
      assert json_response(conn, 404)
    end
  end

  describe "update working_time" do
    test "renders working_time when data is valid", %{conn: conn, user: user} do
      working_time = working_time_fixture(user.id)

      conn = put(conn, ~p"/api/workingtime/#{working_time.id}", working_time: @update_attrs)
      assert %{"start" => "2026-09-21T09:00:00Z"} = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      working_time = working_time_fixture(user.id)
      conn = put(conn, ~p"/api/workingtime/#{working_time.id}", working_time: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete working_time" do
    test "deletes chosen working_time", %{conn: conn, user: user} do
      working_time = working_time_fixture(user.id)

      conn = delete(conn, ~p"/api/workingtime/#{working_time.id}")
      assert response(conn, 204)

      conn = get(conn, ~p"/api/workingtime/#{user.id}/#{working_time.id}")
      assert json_response(conn, 404)
    end
  end
end
