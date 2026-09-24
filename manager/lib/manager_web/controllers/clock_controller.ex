defmodule Time_managerWeb.ClockController do
  use Time_managerWeb, :controller

  alias Time_manager.Account
  alias Time_manager.Attendance
  alias Time_manager.Attendance.Clock

  action_fallback Time_managerWeb.FallbackController

  def index(conn, params) do
    user_id = params["userID"] |> String.to_integer()

    case Account.get_user(user_id) do
      nil -> {:error, :not_found}
      _user ->
        clocks = Attendance.list_clocks(user_id)
        render(conn, :index, clocks: clocks)
    end
  end

  def create(conn, %{"userID" => user_id}) do
    user_id = String.to_integer(user_id)

    with %{} <- Account.get_user(user_id),
         {:ok, %Clock{} = clock} <- Attendance.create_clock(user_id) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/clocks/#{clock.user_id}")
      |> render(:show, clock: clock)
    else
      nil -> {:error, :not_found}
    end
  end
end
