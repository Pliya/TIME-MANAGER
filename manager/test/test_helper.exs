ExUnit.start()

now = DateTime.utc_now() |> DateTime.truncate(:second)

for name <- ["Administrator", "Manager", "Employee"] do
  Time_manager.Repo.insert_all(Time_manager.Account.Role, [%{name: name, inserted_at: now, updated_at: now}],
    on_conflict: :nothing,
    conflict_target: :name
  )
end

Ecto.Adapters.SQL.Sandbox.mode(Time_manager.Repo, :manual)
