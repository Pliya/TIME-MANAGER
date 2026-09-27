defmodule Time_managerWeb.ApiSpec do
  alias OpenApiSpex.{Info, OpenApi, Server}
  @behaviour OpenApiSpex.OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      servers: [
        Server.from_endpoint(Time_managerWeb.Endpoint)
      ],
      info: %Info{
        title: "TIME-MANAGER API",
        version: "1.0.0",
        description: "Documentation of the TIME MANAGER API"
      },
      paths: OpenApiSpex.Paths.from_router(Time_managerWeb.Router)
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
