defmodule Time_managerWeb.WorkingTimeController do
  use Time_managerWeb, :controller

  alias Time_manager.WorkDuration
  alias Time_manager.WorkDuration.WorkingTime

  action_fallback Time_managerWeb.FallbackController

  def index(conn, %{"userID" => user_id} = params) do
    workingtime = WorkDuration.list_working_times_for_user(user_id, params)
    render(conn, :index, workingtime: workingtime)
  end

  def create(conn, %{"userID" => user_id, "working_time" => working_time_params}) do
    attrs = Map.put(working_time_params, "user_id", user_id)

    with {:ok, %WorkingTime{} = working_time} <- WorkDuration.create_working_time(attrs) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", "/api/workingtime/#{user_id}/#{working_time.id}")
      |> render(:show, working_time: working_time)
    end
  end

  def show(conn, %{"userID" => user_id, "id" => id}) do
    # working_time = WorkDuration.get_working_time_for_user!(user_id, id)
    # render(conn, :show, working_time: working_time)
    case WorkDuration.get_working_time_for_user(user_id, id) do
      nil -> {:error, :not_found}
      working_time -> render(conn, :show, working_time: working_time)
    end
  end

  def update(conn, %{"id" => id, "working_time" => working_time_params}) do
    # working_time = WorkDuration.get_working_time!(id)

    # with {:ok, %WorkingTime{} = working_time} <- WorkDuration.update_working_time(working_time, working_time_params) do
    #   render(conn, :show, working_time: working_time)
    # end
    case WorkDuration.get_working_time(id) do
      nil ->
        {:error, :not_found}

      working_time ->
        with {:ok, %WorkingTime{} = working_time} <-
               WorkDuration.update_working_time(working_time, working_time_params) do
          render(conn, :show, working_time: working_time)
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    # working_time = WorkDuration.get_working_time!(id)

    # with {:ok, %WorkingTime{}} <- WorkDuration.delete_working_time(working_time) do
    #   send_resp(conn, :no_content, "")
    # end
    case WorkDuration.get_working_time(id) do
      nil ->
        {:error, :not_found}

      working_time ->
        with {:ok, %WorkingTime{}} <- WorkDuration.delete_working_time(working_time) do
          send_resp(conn, :no_content, "")
        end
    end
  end
end
