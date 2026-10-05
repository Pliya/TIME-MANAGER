defmodule Time_managerWeb.UserJSON do
  alias Time_manager.Account.User

  @doc """
  Renders a list of users.
  """
  def index(%{users: users}) do
    %{data: for(user <- users, do: data(user))}
  end

  def auth(%{
        user: user,
        csrf_token: csrf_token
      }) do
    %{
      data: %{
        user: data(user),
        xsrf_token: csrf_token
      }
    }
  end

  @doc """
  Renders a single user.
  """
  def show(%{user: user}) do
    %{data: data(user)}
  end

  defp data(%User{} = user) do
    %{
      id: user.id,
      username: user.username,
      email: user.email,
      role: if(Ecto.assoc_loaded?(user.role) && user.role, do: user.role.name, else: nil)
    }
  end

end
