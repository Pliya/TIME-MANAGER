defmodule Time_managerWeb.UserController do
  use Time_managerWeb, :controller

  alias Time_manager.Account
  alias Time_manager.Account.User

  action_fallback Time_managerWeb.FallbackController

  def index(conn, params) do
    users = Account.list_users(params)
    render(conn, :index, users: users)
  end

  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Account.create_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/users/#{user}")
      |> render(:show, user: user)
    end
  end

  def show(conn, %{"userID" => id}) do
    case Account.get_user(id) do
      nil ->
        {:error, :not_found}

      user ->
        render(conn, :show, user: user)
    end
  end

  def update(conn, %{"userID" => id, "user" => user_params}) do
    case Account.get_user(id) do
      nil ->
        {:error, :not_found}

      user ->
        with {:ok, %User{} = user} <- Account.update_user(user, user_params) do
          render(conn, :show, user: user)
        end
    end
  end

  def delete(conn, %{"userID" => id}) do
    case Account.get_user(id) do
      nil ->
        {:error, :not_found}

      user ->
        with {:ok, %User{}} <- Account.delete_user(user) do
          send_resp(conn, :no_content, "")
        end
    end
  end
end
