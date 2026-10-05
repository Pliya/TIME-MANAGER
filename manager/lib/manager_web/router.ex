defmodule Time_managerWeb.Router do
  use Time_managerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug OpenApiSpex.Plug.PutApiSpec, module: Time_managerWeb.ApiSpec
  end

  pipeline :browser do
    plug :accepts, ["html"]
  end

  pipeline :authenticated do
    plug Time_managerWeb.AuthPlug
  end

  pipeline :manager_access do
    plug Time_managerWeb.RolePlug, roles: ["Manager"]
  end

  scope "/api", Time_managerWeb do
    pipe_through :api

    scope "/users" do
      post "/sign_up", UserController, :sign_up
      post "/sign_in", UserController, :sign_in
    end

    # ── Users ──────────────────────────────────────────────────────────────
    scope "/users" do
      pipe_through :authenticated

      post "/sign_out", UserController, :sign_out

      # /me : accessible à tout utilisateur connecté
      # DOIT être avant /:userID pour ne pas être capturé comme paramètre
      get "/me", UserController, :me

      scope "/" do
        pipe_through :manager_access

        get    "/",              UserController, :index
        post   "/",              UserController, :create
        get    "/:userID",       UserController, :show
        put    "/:userID",       UserController, :update
        put    "/:userID/role",  UserController, :update_role
        delete "/:userID",       UserController, :delete
      end
    end

    # ── Teams (Manager/Admin uniquement) ──────────────────────────────────
    scope "/teams" do
      pipe_through [:authenticated, :manager_access]

      get    "/",                      TeamController, :index
      post   "/",                      TeamController, :create
      get    "/:teamID",               TeamController, :show
      put    "/:teamID",               TeamController, :update
      delete "/:teamID",               TeamController, :delete
      post   "/:teamID/users/:userID", TeamController, :add_user
      delete "/:teamID/users/:userID", TeamController, :remove_user
    end

    scope "/workingtime" do
      pipe_through :authenticated

      get    "/:userID/:id", WorkingTimeController, :show
      get    "/:userID",     WorkingTimeController, :index
      post   "/:userID",     WorkingTimeController, :create
      put    "/:id",         WorkingTimeController, :update
      delete "/:id",         WorkingTimeController, :delete
    end

    scope "/clocks" do
      pipe_through :authenticated

      get  "/:userID", ClockController, :index
      post "/:userID", ClockController, :create
    end

    get "/openapi", OpenApiSpex.Plug.RenderSpec, []
  end

  scope "/swagger" do
    pipe_through :browser
    get "/swaggerui", OpenApiSpex.Plug.SwaggerUI, path: "/api/openapi"
  end

  if Application.compile_env(:manager, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: Time_managerWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
