defmodule Time_managerWeb.ClockController do
  use Time_managerWeb, :controller

  alias Time_manager.Attendance
  alias Time_manager.Attendance.Clock

  action_fallback Time_managerWeb.FallbackController

  def index(conn, _params) do
    clocks = Attendance.list_clocks()
    render(conn, :index, clocks: clocks)
  end

  def create(conn, %{"clock" => clock_params}) do
    with {:ok, %Clock{} = clock} <- Attendance.create_clock(clock_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/clocks/#{clock}")
      |> render(:show, clock: clock)
    end
  end

  def show(conn, %{"id" => id}) do
    clock = Attendance.get_clock!(id)
    render(conn, :show, clock: clock)
  end

  def update(conn, %{"id" => id, "clock" => clock_params}) do
    clock = Attendance.get_clock!(id)

    with {:ok, %Clock{} = clock} <- Attendance.update_clock(clock, clock_params) do
      render(conn, :show, clock: clock)
    end
  end

  def delete(conn, %{"id" => id}) do
    clock = Attendance.get_clock!(id)

    with {:ok, %Clock{}} <- Attendance.delete_clock(clock) do
      send_resp(conn, :no_content, "")
    end
  end
end
