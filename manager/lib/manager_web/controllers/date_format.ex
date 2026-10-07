defmodule Time_managerWeb.DateFormat do
  @moduledoc """
  Formats datetimes as "YYYY-MM-DD hh:mm:ss" in the API responses.
  """

  def format(nil), do: nil
  def format(datetime), do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S")
end
