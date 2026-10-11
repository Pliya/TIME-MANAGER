defmodule Time_manager.Repo.Migrations.AddManagerToTeams do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :manager_id, references(:users, on_delete: :nilify_all)
    end

    create index(:teams, [:manager_id])
  end
end
