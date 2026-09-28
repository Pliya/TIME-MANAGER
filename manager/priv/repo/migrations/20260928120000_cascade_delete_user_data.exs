defmodule Time_manager.Repo.Migrations.CascadeDeleteUserData do
  use Ecto.Migration

  def change do
    alter table(:clocks) do
      modify :user_id, references(:users, on_delete: :delete_all),
        null: false,
        from: {references(:users, on_delete: :nothing), null: false}
    end

    alter table(:workingtime) do
      modify :user_id, references(:users, on_delete: :delete_all),
        null: false,
        from: {references(:users, on_delete: :nothing), null: false}
    end
  end
end
