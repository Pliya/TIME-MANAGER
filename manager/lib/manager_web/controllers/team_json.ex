defmodule Time_managerWeb.TeamJSON do
  alias Time_manager.Account.Team

  def index(%{teams: teams}), do: %{data: Enum.map(teams, &data/1)}
  def show(%{team: team}), do: %{data: data(team)}

  defp data(%Team{} = team) do
    %{
      id: team.id,
      name: team.name,
      users:
        if(Ecto.assoc_loaded?(team.users),
          do: Enum.map(team.users, fn u -> %{id: u.id, username: u.username, email: u.email} end),
          else: []
        )
    }
  end
end
