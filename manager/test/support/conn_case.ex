defmodule Time_managerWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Time_managerWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint Time_managerWeb.Endpoint

      use Time_managerWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import Time_managerWeb.ConnCase
    end
  end

  setup tags do
    Time_manager.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def log_in(conn, user_id, role \\ "Administrator") do
    csrf_token = Time_manager.Auth.generate_csrf_token()
    {:ok, jwt, _claims} = Time_manager.Auth.generate_token(user_id, role, csrf_token)

    conn
    |> Phoenix.ConnTest.put_req_cookie("time_manager_token", jwt)
    |> Plug.Conn.put_req_header("x-xsrf-token", csrf_token)
  end

  def again(%Plug.Conn{state: :unset} = conn), do: conn
  def again(conn), do: Phoenix.ConnTest.recycle(conn, ~w(accept x-xsrf-token))
end
