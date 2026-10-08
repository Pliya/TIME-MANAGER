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
        status: %OpenApiSpex.Schema{
          type: :boolean,
          description: "true = clock-in, false = clock-out"
        },
        user_id: %OpenApiSpex.Schema{type: :integer}
      },
      required: [:id, :time, :status, :user_id]
    })
  end

  tags(["Clocks"])

  operation(:index,
    summary: "List clock entries for a user",
    parameters: [
      userID: [in: :path, description: "User ID", type: :integer, required: true]
    ],
    responses: [
      ok:
        {"List of clock entries", "application/json",
         %OpenApiSpex.Schema{type: :array, items: ClockResponse}},
      not_found: {"User not found", "application/json", %OpenApiSpex.Schema{type: :object}}
    ]
  )

  def index(conn, %{"userID" => user_id}) do
    case Account.get_user(user_id) do
      nil ->
        {:error, :not_found}

      user ->
        clocks = Attendance.list_clocks(user.id)
        render(conn, :index, clocks: clocks)
    end
  end

  operation(:create,
    summary: "Create a clock entry for a user",
    parameters: [
      userID: [in: :path, description: "User ID", type: :integer, required: true]
    ],
    responses: [
      created: {"Clock entry created", "application/json", ClockResponse},
      not_found: {"User not found", "application/json", %OpenApiSpex.Schema{type: :object}}
    ]
  )

  def create(conn, %{"userID" => user_id} = params) do
    time = parse_time(get_in(params, ["clock", "time"]))

    with %{} = user <- Account.get_user(user_id),
         {:ok, %Clock{} = clock} <- Attendance.create_clock(user.id, time) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/clocks/#{clock.user_id}")
      |> render(:show, clock: clock)
    else
      nil -> {:error, :not_found}
      {:error, _} = error -> error
    end
  end

  defp parse_time(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> DateTime.truncate(datetime, :second)
      _ -> nil
    end
  end

  defp parse_time(_), do: nil
end
