defmodule Time_managerWeb.SharedDataController do
  use Time_managerWeb, :controller
  alias Time_manager.SharedData
  action_fallback Time_managerWeb.FallbackController

  def index(conn, _params) do
    json(conn, %{data: SharedData.all()})
  end

  def update(conn, %{"key" => key, "value" => value}) do
    cond do
      not SharedData.known_key?(key) ->
        {:error, :not_found}

      not SharedData.can_write?(key, conn.assigns[:current_user_role]) ->
        {:error, :forbidden}

      true ->
        {:ok, merged} = SharedData.put(key, value, conn.assigns[:current_user_role])
        json(conn, %{data: merged})
    end
  end
end
