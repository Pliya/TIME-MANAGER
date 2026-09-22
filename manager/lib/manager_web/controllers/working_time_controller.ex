defmodule Time_managerWeb.WorkingTimeController do
  use Time_managerWeb, :controller

  alias Time_manager.WorkDuration
  alias Time_manager.WorkDuration.WorkingTime

  action_fallback Time_managerWeb.FallbackController

  def index(conn, _params) do
    workingtime = WorkDuration.list_workingtime()
    render(conn, :index, workingtime: workingtime)
  end

  def create(conn, %{"working_time" => working_time_params}) do
    with {:ok, %WorkingTime{} = working_time} <- WorkDuration.create_working_time(working_time_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/workingtime/#{working_time}")
      |> render(:show, working_time: working_time)
    end
  end

  def show(conn, %{"id" => id}) do
    working_time = WorkDuration.get_working_time!(id)
    render(conn, :show, working_time: working_time)
  end

  def update(conn, %{"id" => id, "working_time" => working_time_params}) do
    working_time = WorkDuration.get_working_time!(id)

    with {:ok, %WorkingTime{} = working_time} <- WorkDuration.update_working_time(working_time, working_time_params) do
      render(conn, :show, working_time: working_time)
    end
  end

  def delete(conn, %{"id" => id}) do
    working_time = WorkDuration.get_working_time!(id)

    with {:ok, %WorkingTime{}} <- WorkDuration.delete_working_time(working_time) do
      send_resp(conn, :no_content, "")
    end
  end
end
