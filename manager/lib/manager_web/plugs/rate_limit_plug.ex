defmodule Time_managerWeb.RateLimitPlug do
  @moduledoc """
  Limite le nombre de requêtes sur une route (ex. la connexion).

  Options :
  - `:name`      nom du compteur (obligatoire, doit être unique par plug)
  - `:limit`     nombre de requêtes autorisées par fenêtre
  - `:window_ms` durée de la fenêtre en millisecondes
  - `:by`        `:ip` (défaut) ou `{:param, ["user", "email"]}` (chemin dans le corps JSON)

  Au-delà de la limite : réponse 429 + en-tête `retry-after`.
  """
  import Plug.Conn

  alias Time_manager.RateLimiter

  def init(opts) do
    %{
      name: Keyword.fetch!(opts, :name),
      limit: Keyword.fetch!(opts, :limit),
      window_ms: Keyword.fetch!(opts, :window_ms),
      by: Keyword.get(opts, :by, :ip)
    }
  end

  def call(conn, opts) do
    if Application.get_env(:manager, :rate_limit_enabled, true) do
      case identifier(conn, opts.by) do
        nil -> conn
        id -> check(conn, {opts.name, id}, opts)
      end
    else
      conn
    end
  end

  defp check(conn, key, opts) do
    case RateLimiter.hit(key, opts.limit, opts.window_ms) do
      :allow -> conn
      {:deny, retry_after} -> too_many_requests(conn, retry_after)
    end
  end

  defp identifier(conn, :ip), do: client_ip(conn)

  defp identifier(conn, {:param, path}) do
    case get_in(conn.params, path) do
      value when is_binary(value) and value != "" -> value |> String.trim() |> String.downcase()
      _ -> nil
    end
  end

  # Derrière Nginx, remote_ip est celui de Nginx. Nginx AJOUTE l'IP du client
  # à la fin de x-forwarded-for ($proxy_add_x_forwarded_for) : on prend donc la
  # DERNIÈRE valeur, que le client ne peut pas falsifier. Cela suppose que le
  # port 4000 n'est plus joignable directement (faille D).
  defp client_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [value | _] ->
        value |> String.split(",") |> List.last() |> String.trim()

      [] ->
        conn.remote_ip |> :inet.ntoa() |> to_string()
    end
  end

  defp too_many_requests(conn, retry_after) do
    conn
    |> put_resp_header("retry-after", Integer.to_string(retry_after))
    |> put_resp_content_type("application/json")
    |> send_resp(
      :too_many_requests,
      Jason.encode!(%{
        errors: %{detail: "Trop de tentatives. Réessayez dans #{retry_after} secondes."}
      })
    )
    |> halt()
  end
end
