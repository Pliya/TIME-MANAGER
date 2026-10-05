defmodule Time_managerWeb.TeamController do
  use Time_managerWeb, :controller
  alias Time_manager.Account
  alias Time_manager.Account.Team
  action_fallback Time_managerWeb.FallbackController

  def index(conn, _params) do
    teams = Account.list_teams()
    render(conn, :index, teams: teams)
  end

  def show(conn, %{"teamID" => id}) do
    case Account.get_team(id) do
      nil  -> {:error, :not_found}
      team -> render(conn, :show, team: team)
    end
  end

  def create(conn, %{"team" => params}) do
    with {:ok, %Team{} = team} <- Account.create_team(params) do
      team = Time_manager.Repo.preload(team, :users)
      conn |> put_status(:created) |> render(:show, team: team)
    end
  end

  def update(conn, %{"teamID" => id, "team" => params}) do
    case Account.get_team(id) do
      nil  -> {:error, :not_found}
      team ->
        with {:ok, %Team{} = team} <- Account.update_team(team, params) do
          team = Time_manager.Repo.preload(team, :users)
          render(conn, :show, team: team)
        end
    end
  end

  def delete(conn, %{"teamID" => id}) do
    case Account.get_team(id) do
      nil  -> {:error, :not_found}
      team ->
        with {:ok, _} <- Account.delete_team(team) do
          send_resp(conn, :no_content, "")
        end
    end
  end

  def add_user(conn, %{"teamID" => team_id, "userID" => user_id}) do
    with {:ok, team} <- Account.add_user_to_team(team_id, user_id) do
      team = Time_manager.Repo.preload(team, :users)
      render(conn, :show, team: team)
    end
  end

  def remove_user(conn, %{"teamID" => team_id, "userID" => user_id}) do
    with {:ok, team} <- Account.remove_user_from_team(team_id, user_id) do
      team = Time_manager.Repo.preload(team, :users)
      render(conn, :show, team: team)
    end
  end
end
