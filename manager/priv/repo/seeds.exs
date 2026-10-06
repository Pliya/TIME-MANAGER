# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Time_manager.Repo.insert!(%Time_manager.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Ecto.Query

alias Time_manager.Repo
alias Time_manager.Account.Role
alias Time_manager.Account.User

roles = [
  "Administrator",
  "Manager",
  "Employee"
]

Enum.each(roles, fn role_name ->
  Repo.insert_all(
    Role,
    [
      %{
        name: role_name,
        inserted_at: DateTime.utc_now() |> DateTime.truncate(:second),
        updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
      }
    ],
    on_conflict: :nothing,
    conflict_target: :name
  )
end)

administrator_role = Repo.get_by!(Role, name: "Administrator")
employee_role = Repo.get_by!(Role, name: "Employee")

Repo.update_all(
  from(u in User, where: is_nil(u.role_id)),
  set: [role_id: employee_role.id]
)

admin_email = System.get_env("ADMIN_EMAIL")
admin_password = System.get_env("ADMIN_PASSWORD")

if admin_email && admin_password do
  user =
    case Repo.get_by(User, email: admin_email) do
      nil ->
        {:ok, user} =
          Time_manager.Account.register_user(%{
            "username" => System.get_env("ADMIN_USERNAME", "admin"),
            "email" => admin_email,
            "password" => admin_password
          })

        IO.puts("Administrateur #{admin_email} créé.")
        user

      user ->
        user
    end

  user
  |> Ecto.Changeset.change(role_id: administrator_role.id)
  |> Repo.update!()
else
  IO.puts("ADMIN_EMAIL / ADMIN_PASSWORD non définis : aucun administrateur initial créé.")
end
