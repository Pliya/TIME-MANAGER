defmodule Time_manager.SharedData do
  @moduledoc """
  Données partagées entre utilisateurs, gardées en JSON : une ligne par sujet
  (justificatifs, corrections, absences, planning, règles...).

  Un envoi est fusionné avec ce qui est déjà enregistré, pour ne pas effacer
  ce qu'un autre utilisateur vient d'ajouter :
  - liste : les éléments sont mis à jour par leur "id" (ou par leur valeur), les autres sont gardés ;
  - objet : les clés sont mises à jour, une clé à null est supprimée.
  """

  import Ecto.Query
  alias Time_manager.Repo

  defmodule Entry do
    use Ecto.Schema

    schema "shared_data" do
      field :key, :string
      field :value, :map
      timestamps(type: :utc_datetime)
    end
  end

  # Sujet => rôles qui peuvent l'écrire (tout utilisateur connecté peut le lire)
  @writers %{
    "rules" => ["Administrator"],
    "permissions" => ["Administrator"],
    "rightsHistory" => ["Administrator"],
    "planning" => ["Manager", "Administrator"],
    "published" => ["Manager", "Administrator"],
    "overtimeDecisions" => ["Manager", "Administrator"],
    "validatedSheets" => ["Manager", "Administrator"],
    "reminders" => ["Manager", "Administrator"],
    "dismissedAlerts" => ["Manager", "Administrator"],
    "batSignal" => ["Manager", "Administrator"],
    "justifications" => :all,
    "corrections" => :all,
    "absences" => :all,
    "pauses" => :all
  }

  def known_key?(key), do: Map.has_key?(@writers, key)

  def can_write?(key, role) do
    case Map.get(@writers, key) do
      :all -> true
      roles when is_list(roles) -> role in roles
      nil -> false
    end
  end

  # Tous les sujets : %{"corrections" => [...], "rules" => %{...}, ...}
  def all do
    Entry
    |> Repo.all()
    |> Map.new(fn entry -> {entry.key, entry.value["v"]} end)
  end

  # Enregistre un sujet en le fusionnant avec la version en base ; renvoie la valeur fusionnée
  def put(key, incoming, role \\ "Administrator") do
    Repo.transaction(fn ->
      entry = Repo.one(from e in Entry, where: e.key == ^key, lock: "FOR UPDATE")
      old = entry && entry.value["v"]
      value = merge(old, keep_status(key, role, old, incoming))

      (entry || %Entry{key: key})
      |> Ecto.Changeset.change(value: %{"v" => value})
      |> Repo.insert_or_update!()

      value
    end)
  end

  # Seul l'administrateur décide d'une absence : pour les autres, le statut reste celui enregistré
  defp keep_status("absences", role, old, new) when role != "Administrator" and is_list(new) do
    saved = Map.new(old || [], fn absence -> {absence["id"], absence["status"]} end)

    Enum.map(new, fn absence ->
      status =
        cond do
          Map.has_key?(saved, absence["id"]) -> saved[absence["id"]]
          absence["status"] in ["En attente", "Déclaré"] -> absence["status"]
          true -> "En attente"
        end

      Map.put(absence, "status", status)
    end)
  end

  defp keep_status(_key, _role, _old, new), do: new

  defp merge(old, new) when is_list(old) and is_list(new) do
    new_keys = MapSet.new(new, &item_key/1)
    Enum.reject(old, &MapSet.member?(new_keys, item_key(&1))) ++ new
  end

  defp merge(old, new) when is_map(old) and is_map(new) do
    old
    |> Map.merge(new)
    |> Map.reject(fn {_key, value} -> is_nil(value) end)
  end

  defp merge(_old, new) when is_map(new), do: Map.reject(new, fn {_key, value} -> is_nil(value) end)
  defp merge(_old, new), do: new

  defp item_key(%{"id" => id}), do: id
  defp item_key(item), do: item
end
