defmodule Time_managerWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use Time_managerWeb, :controller

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: Time_managerWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> json(%{
      error: "forbidden",
      message: "Vous n'avez pas les permissions nécessaires."
    })
  end

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(html: Time_managerWeb.ErrorHTML, json: Time_managerWeb.ErrorJSON)
    |> render(:"404")
  end

  def call(conn, {:error, :invalid_role}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{
      error: "invalid_role",
      message: "Le rôle doit être Employee ou Manager."
    })
  end
end
