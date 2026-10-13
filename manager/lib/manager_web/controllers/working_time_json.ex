defmodule Time_managerWeb.WorkingTimeJSON do
  alias Time_manager.WorkDuration.WorkingTime
  alias Time_managerWeb.DateFormat

  @doc """
  Renders a list of workingtime.
  """
  def index(%{workingtime: workingtime}) do
    %{data: for(working_time <- workingtime, do: data(working_time))}
  end

  @doc """
  Renders a single working_time.
  """
  def show(%{working_time: working_time}) do
    %{data: data(working_time)}
  end

  defp data(%WorkingTime{} = working_time) do
    %{
      id: working_time.id,
      start: DateFormat.format(working_time.start),
      end: DateFormat.format(working_time.end),
      user_id: working_time.user_id
    }
  end
end
