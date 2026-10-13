defmodule Time_managerWeb.AuthPlug do
  import Plug.Conn

  alias Time_manager.Auth

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> fetch_cookies()
    |> authenticate()
  end

  # defp authenticate(conn) do
  #   case conn.cookies["time_manager_token"] do
  #     nil ->
  #       unauthorized(conn)

  #     token ->
  #       verify_token(conn, token)
  #   end
  # end

  defp authenticate(conn) do
    case token_from(conn) do
      nil ->
        unauthorized(conn)

      token ->
        verify_token(conn, token)
    end
  end

  # Le web envoie le JWT dans le cookie HttpOnly "time_manager_token".
  # L'application mobile l'envoie dans l'en-tête "Authorization: Bearer <jwt>" :
  # elle est servie depuis http://localhost, et le cookie (SameSite=Lax) n'est pas
  # envoyé vers une API sur une autre adresse. Le jeton XSRF reste obligatoire.
  defp token_from(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token | _] when token != "" -> token
      _ -> conn.cookies["time_manager_token"]
    end
  end

  defp verify_token(conn, token) do
    case Auth.verify_token(token) do
      {:ok, claims} ->
        verify_xsrf_token(conn, claims)

      {:error, _reason} ->
        unauthorized(conn)
    end
  end

  defp verify_xsrf_token(conn, claims) do
    request_xsrf =
      conn
      |> get_req_header("x-xsrf-token")
      |> List.first()

    jwt_xsrf = claims["csrf_token"]

    if valid_xsrf?(request_xsrf, jwt_xsrf) do
      conn
      |> assign(:current_user_id, claims["user_id"])
      |> assign(:current_user_role, claims["role"])
      |> assign(:auth_claims, claims)
    else
      forbidden(conn)
    end
  end

  defp valid_xsrf?(request_xsrf, jwt_xsrf)
       when is_binary(request_xsrf) and is_binary(jwt_xsrf) do
    byte_size(request_xsrf) == byte_size(jwt_xsrf) and
      Plug.Crypto.secure_compare(request_xsrf, jwt_xsrf)
  end

  defp valid_xsrf?(_, _), do: false

  defp unauthorized(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      :unauthorized,
      Jason.encode!(%{
        errors: %{detail: "Authentification requise."}
      })
    )
    |> halt()
  end

  defp forbidden(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      :forbidden,
      Jason.encode!(%{
        errors: %{detail: "XSRF token invalide."}
      })
    )
    |> halt()
  end
end
