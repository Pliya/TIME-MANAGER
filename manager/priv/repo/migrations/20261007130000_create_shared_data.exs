defmodule Time_manager.Repo.Migrations.CreateSharedData do
  use Ecto.Migration

  def change do
    create table(:shared_data) do
      add :key, :string, null: false
      add :value, :map, null: false, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:shared_data, [:key])
  end
end
