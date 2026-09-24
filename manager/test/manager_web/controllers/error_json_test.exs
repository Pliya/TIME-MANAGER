defmodule Time_managerWeb.ErrorJSONTest do
  use Time_managerWeb.ConnCase, async: true

  test "renders 404" do
    assert Time_managerWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert Time_managerWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
