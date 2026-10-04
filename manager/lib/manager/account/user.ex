defmodule Time_manager.Account.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :email, :string

    field :password_hash, :string, redact: true

    field :password, :string,
      virtual: true,
      redact: true

    has_many :clocks, Time_manager.Attendance.Clock
    has_many :workingtimes, Time_manager.WorkDuration.WorkingTime

    many_to_many :skills, Time_manager.Account.Skill, join_through: "user_skills"
    many_to_many :teams,  Time_manager.Account.Team,  join_through: "user_teams"

    belongs_to :role, Time_manager.Account.Role
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password])
    |> validate_required([:username, :email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/)
    |> validate_password()
    |> hash_password()
    |> unique_constraint(
      :email,
      message: "cette adresse email est déjà utilisée"
    )
  end

  def registration_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> validate_required([:password])
  end

  defp validate_password(changeset) do
    validate_length(changeset, :password, min: 8)
  end

  defp hash_password(changeset) do
    case get_change(changeset, :password) do
      nil ->
        changeset

      password ->
        put_change(
          changeset,
          :password_hash,
          Bcrypt.hash_pwd_salt(password)
        )
    end
  end
end
