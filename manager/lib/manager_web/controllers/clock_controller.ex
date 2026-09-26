defmodule Time_managerWeb.ClockController do
  use Time_managerWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Time_manager.Account
  alias Time_manager.Attendance
  alias Time_manager.Attendance.Clock

  action_fallback Time_managerWeb.FallbackController

  defmodule ClockResponse do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "Clock",
      description: "A user clock-in / clock-out entry",
      type: :object,
      properties: %{
        id: %OpenApiSpex.Schema{type: :integer},
        time: %OpenApiSpex.Schema{type: :string, format: :"date-time"},
        status: %OpenApiSpex.Schema{type: :boolean, description: "true = clock-in, false = clock-out"},
        user_id: %OpenApiSpex.Schema{type: :integer}
      },
      required: [:id, :time, :status, :user_id]
    })
  end

  tags ["Clocks"]

  operation :index,
    summary: "List clock entries for a user",
    parameters: [
      userID: [in: :path, description: "User ID", type: :integer, required: true]
    ],
    responses: [
      ok: {"List of clock entries", "application/json", %OpenApiSpex.Schema{type: :array, items: ClockResponse}},
      not_found: {"User not found", "application/json", %OpenApiSpex.Schema{type: :object}}
    ]

  def index(conn, params) do
    user_id = params["userID"] |> String.to_integer()

    case Account.get_user!(user_id) do
      nil ->
        {:error, :not_found}
      _user ->
        clocks = Attendance.list_clocks(user_id)
        render(conn, :index, clocks: clocks)
    end
  end

  operation :create,
    summary: "Create a clock entry for a user",
    parameters: [
      userID: [in: :path, description: "User ID", type: :integer, required: true]
    ],
    responses: [
      created: {"Clock entry created", "application/json", ClockResponse},
      not_found: {"User not found", "application/json", %OpenApiSpex.Schema{type: :object}}
    ]

  def create(conn, %{"userID" => user_id}) do
    user_id = String.to_integer(user_id)

    with %{} <- Account.get_user(user_id),
         {:ok, %Clock{} = clock} <- Attendance.create_clock(user_id) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/clocks/#{clock.user_id}")
      |> render(:show, clock: clock)
    else
      nil -> {:error, :not_found}
    end
  end
end
