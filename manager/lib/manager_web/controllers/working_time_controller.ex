defmodule Time_managerWeb.WorkingTimeController do
  use Time_managerWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Time_manager.WorkDuration
  alias Time_manager.WorkDuration.WorkingTime

  action_fallback Time_managerWeb.FallbackController

  defmodule WorkingTimeResponse do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "WorkingTime",
      description: "A working time entry for a user",
      type: :object,
      properties: %{
        id: %OpenApiSpex.Schema{type: :integer},
        start: %OpenApiSpex.Schema{type: :string, format: :"date-time"},
        end: %OpenApiSpex.Schema{type: :string, format: :"date-time"},
        user_id: %OpenApiSpex.Schema{type: :integer}
      },
      required: [:id, :start, :end, :user_id]
    })
  end

  defmodule WorkingTimeRequest do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "WorkingTimeRequest",
      description: "Parameters for a working time entry",
      type: :object,
      properties: %{
        working_time: %OpenApiSpex.Schema{
          type: :object,
          properties: %{
            start: %OpenApiSpex.Schema{type: :string, format: :"date-time"},
            end: %OpenApiSpex.Schema{type: :string, format: :"date-time"}
          },
          required: [:start, :end]
        }
      },
      required: [:working_time]
    })
  end

  tags(["WorkingTimes"])

  operation(:index,
    summary: "List working time entries for a user",
    parameters: [
      userID: [in: :path, description: "User ID", type: :integer, required: true],
      start: [
        in: :query,
        description: "Filter from this datetime (ISO 8601)",
        type: :string,
        required: false
      ],
      end: [
        in: :query,
        description: "Filter until this datetime (ISO 8601)",
        type: :string,
        required: false
      ]
    ],
    responses: [
      ok:
        {"List of working time entries", "application/json",
         %OpenApiSpex.Schema{type: :array, items: WorkingTimeResponse}}
    ]
  )

  def index(conn, %{"userID" => user_id} = params) do
    workingtime = WorkDuration.list_working_times_for_user(user_id, params)
    render(conn, :index, workingtime: workingtime)
  end

  operation(:create,
    summary: "Create a working time entry for a user",
    parameters: [
      userID: [in: :path, description: "User ID", type: :integer, required: true]
    ],
    request_body:
      {"Working time parameters", "application/json", WorkingTimeRequest, required: true},
    responses: [
      created: {"Working time entry created", "application/json", WorkingTimeResponse}
    ]
  )

  def create(conn, %{"userID" => user_id, "working_time" => working_time_params}) do
    attrs = Map.put(working_time_params, "user_id", user_id)

    with {:ok, %WorkingTime{} = working_time} <- WorkDuration.create_working_time(attrs) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", "/api/workingtime/#{user_id}/#{working_time.id}")
      |> render(:show, working_time: working_time)
    end
  end

  operation(:show,
    summary: "Get a specific working time entry",
    parameters: [
      userID: [in: :path, description: "User ID", type: :integer, required: true],
      id: [in: :path, description: "Working time entry ID", type: :integer, required: true]
    ],
    responses: [
      ok: {"The requested working time entry", "application/json", WorkingTimeResponse},
      not_found: {"Entry not found", "application/json", %OpenApiSpex.Schema{type: :object}}
    ]
  )

  def show(conn, %{"userID" => user_id, "id" => id}) do
    case WorkDuration.get_working_time_for_user(user_id, id) do
      nil -> {:error, :not_found}
      working_time -> render(conn, :show, working_time: working_time)
    end
  end

  operation(:update,
    summary: "Update a working time entry",
    parameters: [
      id: [in: :path, description: "Working time entry ID", type: :integer, required: true]
    ],
    request_body: {"Updated parameters", "application/json", WorkingTimeRequest, required: true},
    responses: [
      ok: {"Updated working time entry", "application/json", WorkingTimeResponse},
      not_found: {"Entry not found", "application/json", %OpenApiSpex.Schema{type: :object}}
    ]
  )

  def update(conn, %{"id" => id, "working_time" => working_time_params}) do
    case WorkDuration.get_working_time(id) do
      nil ->
        {:error, :not_found}

      working_time ->
        with {:ok, %WorkingTime{} = working_time} <-
               WorkDuration.update_working_time(working_time, working_time_params) do
          render(conn, :show, working_time: working_time)
        end
    end
  end

  operation(:delete,
    summary: "Delete a working time entry",
    parameters: [
      id: [in: :path, description: "Working time entry ID", type: :integer, required: true]
    ],
    responses: [
      no_content: "Entry deleted successfully",
      not_found: {"Entry not found", "application/json", %OpenApiSpex.Schema{type: :object}}
    ]
  )

  def delete(conn, %{"id" => id}) do
    case WorkDuration.get_working_time(id) do
      nil ->
        {:error, :not_found}

      working_time ->
        with {:ok, %WorkingTime{}} <- WorkDuration.delete_working_time(working_time) do
          send_resp(conn, :no_content, "")
        end
    end
  end
end
