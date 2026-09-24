defmodule Time_managerWeb.Router do
  use Time_managerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end


  scope "/api", Time_managerWeb do
    pipe_through :api

    scope "/users" do
      get "/", UserController, :index
      post "/", UserController, :create
      get "/:userID", UserController, :show
      put "/:userID", UserController, :update
      delete "/:userID", UserController, :delete
    end

    scope "/workingtime" do
      get "/:userID/:id", WorkingTimeController, :show
      get "/:userID", WorkingTimeController, :index
      post "/:userID", WorkingTimeController, :create
      put "/:id", WorkingTimeController, :update
      delete "/:id", WorkingTimeController, :delete
    end

    scope "/clocks" do
      get "/:userID", ClockController, :index
      post "/:userID", ClockController, :create
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
