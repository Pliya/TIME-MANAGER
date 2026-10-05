defmodule Time_managerWeb.TeamController do
  use Time_managerWeb, :controller
  alias Time_manager.Account
  alias Time_manager.Account.Team
  action_fallback Time_managerWeb.FallbackController

  def index(conn, _params) do
    teams =
      if conn.assigns[:current_user_role] == "Administrator" do
        Account.list_teams()
      else
        Account.list_teams_for_manager(conn.assigns[:current_user_id])
      end

    render(conn, :index, teams: teams)
  end

  def show(conn, %{"teamID" => id}) do
    team = Account.get_team(id)

    user_is_member? =
      team != nil and
        Enum.any?(team.users, fn user ->
          user.id == conn.assigns[:current_user_id]
        end)

    cond do
      team == nil ->
        {:error, :not_found}

      conn.assigns[:current_user_role] == "Administrator" ->
        render(conn, :show, team: team)

      team.manager_id == conn.assigns[:current_user_id] ->
        render(conn, :show, team: team)

      user_is_member? ->
        render(conn, :show, team: team)

      true ->
        {:error, :forbidden}
    end
  end

  def create(conn, %{"team" => params}) do
    params =
      if conn.assigns[:current_user_role] == "Manager" do
        Map.put(params, "manager_id", conn.assigns[:current_user_id])
      else
        params
      end

    with {:ok, %Team{} = team} <- Account.create_team(params) do
      team = Time_manager.Repo.preload(team, :users)
      conn |> put_status(:created) |> render(:show, team: team)
    end
  end

  def update(conn, %{"teamID" => id, "team" => params}) do
    case Account.get_team(id) do
      nil ->
        {:error, :not_found}

      team ->
        cond do
          conn.assigns[:current_user_role] == "Administrator" ->
            update_team(conn, team, params)

          team.manager_id == conn.assigns[:current_user_id] ->
            update_team(conn, team, Map.delete(params, "manager_id"))

          true ->
            {:error, :forbidden}
        end
    end
  end

  defp update_team(conn, team, params) do
    with {:ok, %Team{} = team} <- Account.update_team(team, params) do
      team = Time_manager.Repo.preload(team, [:manager, :users])
      render(conn, :show, team: team)
    end
  end

  def delete(conn, %{"teamID" => id}) do
    case Account.get_team(id) do
      nil ->
        {:error, :not_found}

      team ->
        cond do
          conn.assigns[:current_user_role] == "Administrator" ->
            delete_team(conn, team)

          team.manager_id == conn.assigns[:current_user_id] ->
            delete_team(conn, team)

          true ->
            {:error, :forbidden}
        end
    end
  end

  defp delete_team(conn, team) do
    with {:ok, _} <- Account.delete_team(team) do
      send_resp(conn, :no_content, "")
    end
  end

  def add_user(conn, %{"teamID" => team_id, "userID" => user_id}) do
    case Account.get_team(team_id) do
      nil ->
        {:error, :not_found}

      team ->
        cond do
          conn.assigns[:current_user_role] == "Administrator" ->
            add_user_to_team(conn, team_id, user_id)

          team.manager_id == conn.assigns[:current_user_id] ->
            add_user_to_team(conn, team_id, user_id)

          true ->
            {:error, :forbidden}
        end
    end
  end

  defp add_user_to_team(conn, team_id, user_id) do
    with {:ok, team} <- Account.add_user_to_team(team_id, user_id) do
      team = Time_manager.Repo.preload(team, :users)
      render(conn, :show, team: team)
    end
  end

  def remove_user(conn, %{"teamID" => team_id, "userID" => user_id}) do
    case Account.get_team(team_id) do
      nil ->
        {:error, :not_found}

      team ->
        cond do
          conn.assigns[:current_user_role] == "Administrator" ->
            remove_user_from_team(conn, team_id, user_id)

          team.manager_id == conn.assigns[:current_user_id] ->
            remove_user_from_team(conn, team_id, user_id)

          true ->
            {:error, :forbidden}
        end
    end
  end

  defp remove_user_from_team(conn, team_id, user_id) do
    with {:ok, team} <- Account.remove_user_from_team(team_id, user_id) do
      team = Time_manager.Repo.preload(team, :users)
      render(conn, :show, team: team)
    end
  end
end
