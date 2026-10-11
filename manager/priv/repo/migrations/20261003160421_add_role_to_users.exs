defmodule Time_manager.Repo.Migrations.AddRoleToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :role_id, references(:roles, on_delete: :restrict)
    end

    create index(:users, [:role_id])
  end
end
