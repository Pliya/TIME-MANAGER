defmodule Time_manager.Repo.Migrations.CreateWorkingtime do
  use Ecto.Migration

  def change do
    create table(:workingtime) do
      add :start, :naive_datetime, null: false
      add :end, :naive_datetime, null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:workingtime, [:user_id])
  end
end
