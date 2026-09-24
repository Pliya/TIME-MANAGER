defmodule Time_manager.WorkDuration do
  @moduledoc """
  The WorkDuration context.
  """

  import Ecto.Query, warn: false
  alias Time_manager.Repo

  alias Time_manager.WorkDuration.WorkingTime

  @doc """
  Returns the list of workingtime.

  ## Examples

      iex> list_workingtime()
      [%WorkingTime{}, ...]

  """

  def list_working_times_for_user(user_id, params \\ %{}) do
    query = from w in WorkingTime, where: w.user_id == ^user_id

    query
    |> filter_by_start(params["start"])
    |> filter_by_end(params["end"])
    |> Repo.all()
    |> Repo.preload(:user)
  end

  defp filter_by_start(query, start_time) when start_time not in [nil, ""],
    do: from(w in query, where: w.start >= ^start_time)

  defp filter_by_start(query, _), do: query

  defp filter_by_end(query, end_time) when end_time not in [nil, ""],
    do: from(w in query, where: w.end <= ^end_time)

  defp filter_by_end(query, _), do: query

  def list_workingtime do
    WorkingTime
    |> Repo.all()
    |> Repo.preload(:user)
  end

  @doc """
  Gets a single working_time.

  Raises `Ecto.NoResultsError` if the Working time does not exist.

  ## Examples

      iex> get_working_time!(123)
      %WorkingTime{}

      iex> get_working_time!(456)
      ** (Ecto.NoResultsError)

  """

  # def get_working_time!(id) do
  #   WorkingTime
  #   |> Repo.get!(id)
  #   |> Repo.preload(:user)
  # end

  # def get_working_time_for_user!(user_id, id) do
  #   WorkingTime
  #   |> Repo.get_by!([id: id, user_id: user_id])
  #   |> Repo.preload(:user)
  # end

  def get_working_time(id) do
    case Repo.get(WorkingTime, id) do
      nil -> nil
      working_time -> Repo.preload(working_time, :user)
    end
  end

  def get_working_time_for_user(user_id, id) do
    case Repo.get_by(WorkingTime, id: id, user_id: user_id) do
      nil -> nil
      working_time -> Repo.preload(working_time, :user)
    end
  end

  @doc """
  Creates a working_time.
  ## Examples

      iex> create_working_time(%{field: value})
      {:ok, %WorkingTime{}}

      iex> create_working_time(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_working_time(attrs \\ %{}) do
    %WorkingTime{}
    |> WorkingTime.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, updated_wt} -> {:ok, Repo.preload(updated_wt, :user)}
      error -> error
    end
  end

  @doc """
  Updates a working_time.

  ## Examples

      iex> update_working_time(working_time, %{field: new_value})
      {:ok, %WorkingTime{}}

      iex> update_working_time(working_time, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_working_time(%WorkingTime{} = working_time, attrs) do
    working_time
    |> WorkingTime.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_wt} -> {:ok, Repo.preload(updated_wt, :user)}
      error -> error
    end
  end

  @doc """
  Deletes a working_time.

  ## Examples

      iex> delete_working_time(working_time)
      {:ok, %WorkingTime{}}

      iex> delete_working_time(working_time)
      {:error, %Ecto.Changeset{}}

  """
  def delete_working_time(%WorkingTime{} = working_time) do
    Repo.delete(working_time)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking working_time changes.

  ## Examples

      iex> change_working_time(working_time)
      %Ecto.Changeset{data: %WorkingTime{}}

  """
  def change_working_time(%WorkingTime{} = working_time, attrs \\ %{}) do
    WorkingTime.changeset(working_time, attrs)
  end
end
