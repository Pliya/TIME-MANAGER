defmodule Time_managerWeb.ClockControllerTest do
  use Time_managerWeb.ConnCase

  import Time_manager.AccountFixtures
  import Time_manager.AttendanceFixtures

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json"), user: user_fixture()}
  end

  describe "index" do
    test "lists the clocks of the user", %{conn: conn, user: user} do
      clock = clock_fixture(user.id)

      conn = get(conn, ~p"/api/clocks/#{user.id}")
      user_id = user.id

      assert [%{"id" => id, "status" => true, "user_id" => ^user_id}] =
               json_response(conn, 200)["data"]

      assert id == clock.id
    end

    test "renders 404 for an unknown user", %{conn: conn} do
      conn = get(conn, ~p"/api/clocks/-1")
      assert json_response(conn, 404)
    end
  end

  describe "create clock" do
    test "creates a clock-in for the user", %{conn: conn, user: user} do
      conn = post(conn, ~p"/api/clocks/#{user.id}")
      user_id = user.id

      assert %{"status" => true, "user_id" => ^user_id, "time" => time} =
               json_response(conn, 201)["data"]

      assert time =~ ~r/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/
    end

    test "clock in then clock out with the times sent by the frontend", %{conn: conn, user: user} do
      post(conn, ~p"/api/clocks/#{user.id}", clock: %{status: true, time: "2026-09-29 08:30:00"})

      conn =
        post(conn, ~p"/api/clocks/#{user.id}",
          clock: %{status: false, time: "2026-09-29 12:00:00"}
        )

      assert %{"status" => false, "time" => "2026-09-29 12:00:00"} =
               json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/workingtime/#{user.id}")

      assert [%{"start" => "2026-09-29 08:30:00", "end" => "2026-09-29 12:00:00"}] =
               json_response(conn, 200)["data"]
    end

    test "renders 404 for an unknown user", %{conn: conn} do
      conn = post(conn, ~p"/api/clocks/-1")
      assert json_response(conn, 404)
    end
  end
end
