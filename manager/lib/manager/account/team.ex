defmodule Time_manager.Account.Team do
  use Ecto.Schema
  import Ecto.Changeset

  schema "teams" do
    field :name, :string

    belongs_to :manager, Time_manager.Account.User
    many_to_many :users, Time_manager.Account.User, join_through: "user_teams", on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :manager_id])
    |> validate_required([:name, :manager_id])
    |> unique_constraint(:name)
  end
end
