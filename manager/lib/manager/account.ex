defmodule Time_manager.Account do
  @moduledoc """
  The Account context.
  """

  import Ecto.Query, warn: false
  alias Time_manager.Repo

  alias Time_manager.Account.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User) |> Repo.preload(:role)
  end

  def list_users(params) do
    query = from(u in User)

    query =
      if params["email"] do
        where(query, [u], u.email == ^params["email"])
      else
        query
      end

    query =
      if params["username"] do
        where(query, [u], u.username == ^params["username"])
      else
        query
      end

    Repo.all(query) |> Repo.preload(:role)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  def get_user(id), do: Repo.get(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    role_name = Map.get(attrs, "role", "Employee")

    if role_name not in ["Employee", "Manager"] do
      {:error, :invalid_role}
    else
      role = Repo.get_by!(Time_manager.Account.Role, name: role_name)

      %User{}
      |> User.changeset(attrs)
      |> Ecto.Changeset.put_change(:role_id, role.id)
      |> Repo.insert()
    end
  end

  def register_user(attrs \\ %{}) do
    employee_role = Repo.get_by!(Time_manager.Account.Role, name: "Employee")

    %User{}
    |> User.registration_changeset(attrs)
    |> Ecto.Changeset.put_change(:role_id, employee_role.id)
    |> Repo.insert()
  end

  def authenticate_user(email, password) do
    case Repo.get_by(User, email: email) |> Repo.preload(:role) do
      nil ->
        {:error, :invalid_credentials}

      %User{password_hash: nil} ->
        {:error, :invalid_credentials}

      %User{role: nil} ->
        {:error, :invalid_role}

      user ->
        if Bcrypt.verify_pass(password, user.password_hash) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
    end
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @valid_roles ~w(Employee Manager Administrator)

  @valid_roles ~w(Employee Manager)

  def update_user_role(user_id, role_name) when role_name in @valid_roles do
    case Repo.get(User, user_id) do
      nil ->
        {:error, :not_found}

      user ->
        role = Repo.get_by!(Time_manager.Account.Role, name: role_name)

        user
        |> Ecto.Changeset.change(role_id: role.id)
        |> Repo.update()
    end
  end

  def update_user_role(_user_id, _role_name), do: {:error, :invalid_role}

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  # ── Teams ──────────────────────────────────────────────────────────────

  alias Time_manager.Account.Team

  def list_teams do
    Repo.all(Team)
    |> Repo.preload([:manager, :users])
  end

  def list_teams_for_manager(user_id) do
    Team
    |> join(:left, [t], ut in "user_teams", on: ut.team_id == t.id and ut.user_id == ^user_id)
    |> where([t, ut], t.manager_id == ^user_id or not is_nil(ut.user_id))
    |> distinct(true)
    |> Repo.all()
    |> Repo.preload([:manager, :users])
  end

  def get_team(id) do
    Repo.get(Team, id) |> Repo.preload(:users)
  end

  def create_team(attrs) do
    %Team{}
    |> Team.changeset(attrs)
    |> Repo.insert()
  end

  def update_team(%Team{} = team, attrs) do
    team
    |> Team.changeset(attrs)
    |> Repo.update()
  end

  def delete_team(%Team{} = team) do
    Repo.delete(team)
  end

  def add_user_to_team(team_id, user_id) do
    team = Repo.get!(Team, team_id) |> Repo.preload(:users)
    user = Repo.get!(User, user_id)

    team
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:users, Enum.uniq([user | team.users]))
    |> Repo.update()
  end

  def remove_user_from_team(team_id, user_id) do
    team = Repo.get!(Team, team_id) |> Repo.preload(:users)
    uid = String.to_integer("#{user_id}")

    team
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(
      :users,
      Enum.reject(team.users, fn u -> u.id == uid end)
    )
    |> Repo.update()
  end
end
