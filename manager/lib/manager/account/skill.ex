defmodule Time_manager.Account.Skill do
  use Ecto.Schema
  import Ecto.Changeset

  schema "skills" do
    field :label, :string

    many_to_many :users, Time_manager.Account.User, join_through: "user_skills"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(skill, attrs) do
    skill
    |> cast(attrs, [:label])
    |> validate_required([:label])
    |> validate_length(:label, min: 1)
    |> unique_constraint(:label)
  end
end
