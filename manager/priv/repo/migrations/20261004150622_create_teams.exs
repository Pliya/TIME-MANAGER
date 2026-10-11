defmodule Time_manager.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :name, :string, null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:teams, [:name])

    create table(:user_teams, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :team_id, references(:teams, on_delete: :delete_all), null: false
    end

    create unique_index(:user_teams, [:user_id, :team_id])
    create index(:user_teams, [:team_id])
  end
end
