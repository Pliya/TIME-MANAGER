# Données de démonstration : un compte par rôle, une équipe et ~3 semaines de pointages.
#
#     mix run priv/repo/demo_data.exs
#
# Le script peut être relancé : il supprime d'abord les comptes de démo (et leurs données) puis les recrée.
# Mot de passe de tous les comptes : Gotham2026!
#
# Les dates sont calculées à partir d'aujourd'hui, pour que les écrans « semaine » et « mois » aient des chiffres.

import Ecto.Query

alias Time_manager.Repo
alias Time_manager.Account
alias Time_manager.Account.{Role, User, Team}
alias Time_manager.Attendance.Clock
alias Time_manager.WorkDuration.WorkingTime

password = "Gotham2026!"

# ── Rôles (au cas où seeds.exs n'a pas encore été lancé) ──────────────
now = DateTime.utc_now() |> DateTime.truncate(:second)

for name <- ["Administrator", "Manager", "Employee"] do
  Repo.insert_all(Role, [%{name: name, inserted_at: now, updated_at: now}],
    on_conflict: :nothing,
    conflict_target: :name
  )
end

# ── Comptes ──────────────────────────────────────────────────────────
accounts = [
  {"albert_rh", "albert@gotham.gov", "Administrator"},
  {"jim_gordon", "gordon@gotham.gov", "Manager"},
  {"john_doe", "john.doe@gotham.gov", "Employee"},
  {"selina_kyle", "selina.kyle@gotham.gov", "Employee"},
  {"renee_montoya", "renee.montoya@gotham.gov", "Employee"},
  {"harvey_dent", "harvey.dent@gotham.gov", "Employee"}
]

emails = Enum.map(accounts, fn {_, email, _} -> email end)
team_name = "Brigade de nuit"

# Nettoyage : les pointages, temps et appartenances aux équipes partent avec l'utilisateur
Repo.delete_all(from t in Team, where: t.name == ^team_name)
Repo.delete_all(Time_manager.SharedData.Entry)
Repo.delete_all(from u in User, where: u.email in ^emails)

users =
  for {username, email, role} <- accounts, into: %{} do
    {:ok, user} = Account.register_user(%{"username" => username, "email" => email, "password" => password})
    # Rôle posé directement : l'API refuse (à juste titre) de nommer un administrateur
    role_id = Repo.get_by!(Role, name: role).id
    user = user |> Ecto.Changeset.change(role_id: role_id) |> Repo.update!()
    {username, user}
  end

# ── Équipe managée par Jim Gordon (Harvey Dent reste hors équipe pour tester l'ajout) ──
{:ok, team} = Account.create_team(%{"name" => team_name, "manager_id" => users["jim_gordon"].id})

for name <- ["john_doe", "selina_kyle", "renee_montoya"] do
  {:ok, _} = Account.add_user_to_team(team.id, users[name].id)
end

# ── Pointages et temps de travail ────────────────────────────────────
today = Date.utc_today()

# "08:00" le jour J  →  DateTime (les heures sont affichées telles quelles par le front)
at = fn date, time ->
  {:ok, t} = Time.from_iso8601(time <> ":00")
  DateTime.new!(date, t, "Etc/UTC")
end

weekday? = fn date -> Date.day_of_week(date) <= 5 end

# Une session = un temps de travail + son pointage d'arrivée et de sortie
add_session = fn user, start_date, start_time, end_date, end_time ->
  start = at.(start_date, start_time)
  finish = at.(end_date, end_time)
  Repo.insert!(%WorkingTime{user_id: user.id, start: start, end: finish})
  Repo.insert!(%Clock{user_id: user.id, status: true, time: start})
  Repo.insert!(%Clock{user_id: user.id, status: false, time: finish})
end

day_shift = fn user, date, from, to -> add_session.(user, date, from, date, to) end
night_shift = fn user, date -> add_session.(user, date, "22:00", Date.add(date, 1), "06:00") end

# Les 21 jours qui précèdent aujourd'hui, du plus ancien au plus récent
past_days = for offset <- 21..1//-1, do: Date.add(today, -offset)
first_of_month = Date.beginning_of_month(today)

for date <- past_days do
  # John Doe : journées classiques, une nuit le mercredi
  cond do
    Date.day_of_week(date) == 3 -> night_shift.(users["john_doe"], date)
    weekday?.(date) -> day_shift.(users["john_doe"], date, "08:00", "16:30")
    true -> :repos
  end

  # Selina Kyle : agent de nuit, une nuit sur deux… et 3 nuits d'affilée en début de mois
  cond do
    Date.compare(date, first_of_month) != :lt and Date.diff(date, first_of_month) < 3 ->
      night_shift.(users["selina_kyle"], date)

    rem(Date.diff(date, today), 2) == 0 ->
      night_shift.(users["selina_kyle"], date)

    true ->
      :repos
  end

  # Renee Montoya : longues journées → heures sup ; une journée de 16 h hier (durée inhabituelle)
  cond do
    Date.diff(today, date) == 1 -> day_shift.(users["renee_montoya"], date, "06:00", "22:00")
    weekday?.(date) -> day_shift.(users["renee_montoya"], date, "07:00", "18:00")
    true -> day_shift.(users["renee_montoya"], date, "08:00", "18:00")
  end

  # Harvey Dent (hors équipe) et Jim Gordon : journées régulières
  if weekday?.(date) do
    day_shift.(users["harvey_dent"], date, "09:00", "17:00")
    day_shift.(users["jim_gordon"], date, "08:00", "18:00")
  end
end

# Aujourd'hui : Renee a fini sa matinée ; John n'a jamais pointé sa sortie d'hier soir (sortie oubliée)
day_shift.(users["renee_montoya"], today, "06:00", "12:00")
Repo.insert!(%Clock{user_id: users["john_doe"].id, status: true, time: at.(Date.add(today, -1), "20:00")})

IO.puts("""

Données de démo créées (mot de passe : #{password})
  Administrateur : albert@gotham.gov
  Manager        : gordon@gotham.gov   (équipe « #{team_name} »)
  Employés       : john.doe@gotham.gov, selina.kyle@gotham.gov, renee.montoya@gotham.gov
  Hors équipe    : harvey.dent@gotham.gov
""")
