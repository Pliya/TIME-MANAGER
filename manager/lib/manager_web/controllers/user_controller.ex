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
            email: %OpenApiSpex.Schema{type: :string},
            password: %OpenApiSpex.Schema{type: :string, format: :password},
            role: %OpenApiSpex.Schema{type: :string, enum: ["Employee", "Manager"]}
          },
          required: [:username, :email, :password, :role]
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
      user = Time_manager.Repo.preload(user, :role)

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
      nil ->
        {:error, :not_found}

      user ->
        user = Time_manager.Repo.preload(user, :role)
        render(conn, :show, user: user)
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
          user = Time_manager.Repo.preload(user, :role)
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
         user <- Time_manager.Repo.preload(user, :role),
         csrf_token <- Auth.generate_csrf_token(),
         {:ok, jwt, _claims} <- Auth.generate_token(user.id, user.role.name, csrf_token) do
      conn
      |> put_resp_cookie(
        "time_manager_token",
        jwt,
        http_only: true,
        secure: secure_cookie?(),
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

        case Auth.generate_token(user.id, user.role.name, csrf_token) do
          {:ok, jwt, _claims} ->
            conn
            |> put_resp_cookie(
              "time_manager_token",
              jwt,
              http_only: true,
              secure: secure_cookie?(),
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

  # GET /api/users/me — tout utilisateur authentifié
  # Lit le user_id depuis les claims du JWT (mis par AuthPlug dans conn.assigns)
  def me(conn, _params) do
    user_id = conn.assigns.current_user_id

    case Account.get_user(user_id) do
      nil ->
        # Cas rare : le token est valide mais le user a été supprimé
        conn
        |> put_status(:not_found)
        |> json(%{errors: %{detail: "Utilisateur introuvable."}})

      user ->
        user = Time_manager.Repo.preload(user, :role)
        render(conn, :show, user: user)
    end
  end

  # PUT /api/users/:userID/role — Manager/Admin uniquement
  def update_role(conn, %{"userID" => id, "user" => %{"role" => role_name}}) do
    case Account.update_user_role(id, role_name) do
      {:ok, user} ->
        user = Time_manager.Repo.preload(user, :role)
        render(conn, :show, user: user)

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :invalid_role} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          errors: %{
            detail: "Rôle invalide. Valeurs acceptées : Employee, Manager, Administrator."
          }
        })

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  # Cookie envoyé uniquement en HTTPS quand COOKIE_SECURE=true (production)
  defp secure_cookie? do
    System.get_env("COOKIE_SECURE") == "true"
  end
end
