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

  pipeline :sign_in_limit do
    plug Time_managerWeb.RateLimitPlug, name: :sign_in_ip, limit: 10, window_ms: 60_000, by: :ip

    plug Time_managerWeb.RateLimitPlug,
      name: :sign_in_email,
      limit: 5,
      window_ms: 60_000,
      by: {:param, ["user", "email"]}
  end

  pipeline :manager_access do
    plug Time_managerWeb.RolePlug, roles: ["Manager"]
  end

  pipeline :admin_access do
    plug Time_managerWeb.RolePlug, roles: ["Administrator"]
  end

  scope "/api", Time_managerWeb do
    pipe_through :api

    scope "/users" do
      pipe_through :sign_in_limit

      post "/sign_in", UserController, :sign_in
    end

    # ── Users ──────────────────────────────────────────────────────────────
    scope "/users" do
      pipe_through :authenticated

      post "/sign_out", UserController, :sign_out
      get "/me", UserController, :me

      # Routes accessibles aux Managers et Administrators
      scope "/" do
        pipe_through :manager_access

        get "/", UserController, :index
        get "/:userID", UserController, :show
        put "/:userID", UserController, :update
        delete "/:userID", UserController, :delete
      end

      # Routes accessibles uniquement aux Administrators
      scope "/" do
        pipe_through :admin_access

        post "/", UserController, :create
        put "/:userID/role", UserController, :update_role
      end
    end

    # ── Données partagées (justificatifs, corrections, absences, planning, règles...) ──
    scope "/data" do
      pipe_through :authenticated

      get "/", SharedDataController, :index
      put "/:key", SharedDataController, :update
    end

    # ── Teams (Manager/Admin uniquement) ──────────────────────────────────
    # ── Teams ─────────────────────────────────────────────────────────────
    scope "/teams" do
      pipe_through :authenticated

      get "/", TeamController, :index
      get "/:teamID", TeamController, :show

      scope "/" do
        pipe_through :manager_access

        post "/", TeamController, :create
        put "/:teamID", TeamController, :update
        delete "/:teamID", TeamController, :delete
        post "/:teamID/users/:userID", TeamController, :add_user
        delete "/:teamID/users/:userID", TeamController, :remove_user
      end
    end

    scope "/workingtime" do
      pipe_through :authenticated

      get "/:userID/:id", WorkingTimeController, :show
      get "/:userID", WorkingTimeController, :index
      post "/:userID", WorkingTimeController, :create
      put "/:id", WorkingTimeController, :update
      delete "/:id", WorkingTimeController, :delete
    end

    scope "/clocks" do
      pipe_through :authenticated

      get "/:userID", ClockController, :index
      post "/:userID", ClockController, :create
    end
  end

  if Application.compile_env(:manager, :dev_routes) do
    scope "/api" do
      pipe_through :api
      get "/openapi", OpenApiSpex.Plug.RenderSpec, []
    end

    scope "/swagger" do
      pipe_through :browser
      get "/swaggerui", OpenApiSpex.Plug.SwaggerUI, path: "/api/openapi"
    end
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
