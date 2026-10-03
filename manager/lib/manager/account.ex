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
    Repo.all(User)
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

    Repo.all(query)
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
    employee_role = Repo.get_by!(Time_manager.Account.Role, name: "Employee")

    %User{}
    |> User.changeset(attrs)
    |> Ecto.Changeset.put_change(:role_id, employee_role.id)
    |> Repo.insert()
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

  # Skills

  def list_skills do
    Repo.all(Time_manager.Account.Skill)
  end

  def get_skill!(id) do
    Repo.get!(Time_manager.Account.Skill, id)
  end

  def create_skill(attrs \\ %{}) do
    %Time_manager.Account.Skill{}
    |> Time_manager.Account.Skill.changeset(attrs)
    |> Repo.insert()
  end

  def update_skill(%Time_manager.Account.Skill{} = skill, attrs) do
    skill
    |> Time_manager.Account.Skill.changeset(attrs)
    |> Repo.update()
  end

  def delete_skill(%Time_manager.Account.Skill{} = skill) do
    Repo.delete(skill)
  end

  def list_user_skills(user_id) do
    user =
      User
      |> Repo.get!(user_id)
      |> Repo.preload(:skills)

    user.skills
  end

  def add_skill_to_user(user_id, skill_id) do
    user = Repo.get!(User, user_id)
    skill = Repo.get!(Time_manager.Account.Skill, skill_id)

    user
    |> Repo.preload(:skills)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:skills, Enum.uniq([skill | user.skills]))
    |> Repo.update()
  end

  def remove_skill_from_user(user_id, skill_id) do
    user = Repo.get!(User, user_id)
    skill = Repo.get!(Time_manager.Account.Skill, skill_id)

    user
    |> Repo.preload(:skills)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(
      :skills,
      Enum.reject(user.skills, fn current_skill ->
        current_skill.id == skill.id
      end)
    )
    |> Repo.update()
  end
end
