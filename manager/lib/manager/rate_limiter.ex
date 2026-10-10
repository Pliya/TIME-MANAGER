defmodule Time_manager.RateLimiter do
  @moduledoc """
  Limiteur de requêtes simple, en mémoire (table ETS), par fenêtre fixe.

  `hit(cle, limite, fenetre_ms)` compte un appel pour `cle` et répond :
  - `:allow` tant que la limite n'est pas dépassée ;
  - `{:deny, secondes}` ensuite (secondes = temps avant la prochaine fenêtre).

  Les compteurs sont perdus au redémarrage et ne sont pas partagés entre
  plusieurs serveurs : suffisant pour une seule instance Phoenix.
  """
  use GenServer

  @table :time_manager_rate_limiter
  @cleanup_every :timer.minutes(1)

  def start_link(_opts), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def hit(key, limit, window_ms) do
    now = System.system_time(:millisecond)
    window = div(now, window_ms)
    expires_at = (window + 1) * window_ms
    entry_key = {key, window}

    count = :ets.update_counter(@table, entry_key, {2, 1}, {entry_key, 0, expires_at})

    if count > limit do
      {:deny, div(expires_at - now, 1000) + 1}
    else
      :allow
    end
  end

  @impl true
  def init(_) do
    :ets.new(@table, [:named_table, :public, :set, write_concurrency: true])
    schedule_cleanup()
    {:ok, nil}
  end

  @impl true
  def handle_info(:cleanup, state) do
    now = System.system_time(:millisecond)
    :ets.select_delete(@table, [{{:_, :_, :"$1"}, [{:<, :"$1", now}], [true]}])
    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup, do: Process.send_after(self(), :cleanup, @cleanup_every)
end
