defmodule Time_managerWeb.UserController do
  use Time_managerWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Time_manager.Account
  alias Time_manager.Account.User
  alias Time_manager.Auth

  action_fallback Time_managerWeb.FallbackController

  defmodule UserResponse do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "User",
      description: "A platform user",
      type: :object,
      properties: %{
        id: %OpenApiSpex.Schema{type: :integer},
        username: %OpenApiSpex.Schema{type: :string},
        email: %OpenApiSpex.Schema{type: :string}
      },
      required: [:id, :username, :email]
    })
  end

  defmodule UserRequest do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "UserRequest",
      description: "Parameters for creating or updating a user",
      type: :object,
      properties: %{
        user: %OpenApiSpex.Schema{
          type: :object,
          properties: %{
            username: %OpenApiSpex.Schema{type: :string},
            email: %OpenApiSpex.Schema{type: :string}
          },
          required: [:username, :email]
        }
      },
      required: [:user]
    })
  end

  tags(["Users"])

  operation(:index,
    summary: "List all users",
    responses: [
      ok:
        {"List of users", "application/json",
         %OpenApiSpex.Schema{type: :array, items: UserResponse}}
    ]
  )

  def index(conn, params) do
    users = Account.list_users(params)
    render(conn, :index, users: users)
  end

  operation(:create,
    summary: "Create a user",
    request_body: {"User parameters", "application/json", UserRequest, required: true},
    responses: [
      created: {"Created user", "application/json", UserResponse}
    ]
  )

  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Account.create_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/users/#{user}")
      |> render(:show, user: user)
    end
  end

  operation(:show,
    summary: "Get a user by ID",
    parameters: [
      userID: [in: :path, description: "User ID", type: :integer, required: true]
    ],
    responses: [
      ok: {"The requested user", "application/json", UserResponse},
      not_found: {"User not found", "application/json", %OpenApiSpex.Schema{type: :object}}
    ]
  )

  def show(conn, %{"userID" => id}) do
    case Account.get_user(id) do
      nil -> {:error, :not_found}
      user -> render(conn, :show, user: user)
    end
  end

  operation(:update,
    summary: "Update a user",
    parameters: [
      userID: [in: :path, description: "User ID", type: :integer, required: true]
    ],
    request_body: {"Updated user parameters", "application/json", UserRequest, required: true},
    responses: [
      ok: {"Updated user", "application/json", UserResponse},
      not_found: {"User not found", "application/json", %OpenApiSpex.Schema{type: :object}}
    ]
  )

  def update(conn, %{"userID" => id, "user" => user_params}) do
    case Account.get_user(id) do
      nil ->
        {:error, :not_found}

      user ->
        with {:ok, %User{} = user} <- Account.update_user(user, user_params) do
          render(conn, :show, user: user)
        end
    end
  end

  operation(:delete,
    summary: "Delete a user",
    parameters: [
      userID: [in: :path, description: "User ID", type: :integer, required: true]
    ],
    responses: [
      no_content: "User deleted successfully",
      not_found: {"User not found", "application/json", %OpenApiSpex.Schema{type: :object}}
    ]
  )

  def delete(conn, %{"userID" => id}) do
    case Account.get_user(id) do
      nil ->
        {:error, :not_found}

      user ->
        with {:ok, %User{}} <- Account.delete_user(user) do
          send_resp(conn, :no_content, "")
        end
    end
  end

  def sign_up(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Account.register_user(user_params),
         csrf_token <- Auth.generate_csrf_token(),
         {:ok, jwt, _claims} <- Auth.generate_token(user.id, csrf_token) do
      conn
      |> put_resp_cookie(
        "time_manager_token",
        jwt,
        http_only: true,
        secure: false,
        same_site: "Lax",
        max_age: 60 * 60 * 24 * 30,
        path: "/"
      )
      |> put_status(:created)
      |> render(:auth, user: user, csrf_token: csrf_token)
    end
  end

  def sign_in(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Account.authenticate_user(email, password) do
      {:ok, user} ->
        csrf_token = Auth.generate_csrf_token()

        case Auth.generate_token(user.id, csrf_token) do
          {:ok, jwt, _claims} ->
            conn
            |> put_resp_cookie(
              "time_manager_token",
              jwt,
              http_only: true,
              secure: false,
              same_site: "Lax",
              max_age: 60 * 60 * 24 * 30,
              path: "/"
            )
            |> render(:auth, user: user, csrf_token: csrf_token)

          {:error, _reason} ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{
              errors: %{
                detail: "Impossible de générer le token."
              }
            })
        end

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{
          errors: %{
            detail: "Email ou mot de passe incorrect."
          }
        })
    end
  end

  def sign_out(conn, _params) do
    conn
    |> delete_resp_cookie(
      "time_manager_token",
      path: "/"
    )
    |> send_resp(:no_content, "")
  end
end
