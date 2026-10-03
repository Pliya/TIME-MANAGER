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

# Roles prédéfinis de l'application
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

# Récupération des rôles
administrator_role = Repo.get_by!(Role, name: "Administrator")
employee_role = Repo.get_by!(Role, name: "Employee")

# Les utilisateurs sans rôle deviennent des employés par défaut
Repo.update_all(
  from(u in User, where: is_nil(u.role_id)),
  set: [role_id: employee_role.id]
)

# Le compte Isaac devient administrateur
case Repo.get_by(User, email: "isaac@test.com") do
  nil ->
    IO.puts("Utilisateur isaac@test.com introuvable.")

  user ->
    user
    |> Ecto.Changeset.change(role_id: administrator_role.id)
    |> Repo.update!()

    IO.puts("isaac@test.com est maintenant Administrator.")
end
