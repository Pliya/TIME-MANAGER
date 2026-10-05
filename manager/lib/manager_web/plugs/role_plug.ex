defmodule Time_managerWeb.RolePlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    allowed_roles = Keyword.get(opts, :roles, [])

    current_role = conn.assigns[:current_user_role]

    cond do
      current_role == "Administrator" ->
        conn

      current_role in allowed_roles ->
        conn

      true ->
        conn
        |> put_status(:forbidden)
        |> Phoenix.Controller.json(%{
          error: "forbidden",
          message: "Vous n'avez pas les permissions nécessaires."
        })
        |> halt()
    end
  end
end
