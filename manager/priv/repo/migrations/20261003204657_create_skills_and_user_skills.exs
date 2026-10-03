defmodule Time_manager.Repo.Migrations.CreateSkillsAndUserSkills do
  use Ecto.Migration

  def change do
    create table(:skills) do
      add :label, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:skills, [:label])

    create table(:user_skills, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :skill_id, references(:skills, on_delete: :delete_all), null: false
    end

    create unique_index(:user_skills, [:user_id, :skill_id])
    create index(:user_skills, [:skill_id])
  end
end
