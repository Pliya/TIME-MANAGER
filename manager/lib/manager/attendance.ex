defmodule Time_manager.Attendance do
  @moduledoc """
  The Attendance context.
  """

  import Ecto.Query, warn: false
  alias Time_manager.Repo

  alias Time_manager.Attendance.Clock
  alias Time_manager.WorkDuration

  @doc """
  Returns the list of clocks.

  ## Examples

      iex> list_clocks()
      [%Clock{}, ...]

  """
  def list_clocks(user_id) do
    Clock
    |> where(user_id: ^user_id)
    |> Repo.all()
  end

  @doc """
  Gets a single clock.

  Raises `Ecto.NoResultsError` if the Clock does not exist.

  ## Examples

      iex> get_clock!(123)
      %Clock{}

      iex> get_clock!(456)
      ** (Ecto.NoResultsError)

  """
  def get_clock!(id), do: Repo.get!(Clock, id)

  @doc """
  Creates a clock.

  ## Examples

      iex> create_clock(%{field: value})
      {:ok, %Clock{}}

      iex> create_clock(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_clock(user_id) do
    last_clock =
      from(c in Clock,
        where: c.user_id == ^user_id,
        order_by: [desc: c.time, desc: c.id],
        limit: 1
      )
      |> Repo.one()

    now = DateTime.utc_now() |> DateTime.truncate(:second)
    clocking_out? = last_clock != nil and last_clock.status

    Repo.transaction(fn ->
      clock =
        %Clock{user_id: user_id, status: not clocking_out?, time: now}
        |> Clock.changeset(%{})
        |> Repo.insert()
        |> unwrap_or_rollback()

      if clocking_out? and DateTime.compare(last_clock.time, now) == :lt do
        WorkDuration.create_working_time(%{user_id: user_id, start: last_clock.time, end: now})
        |> unwrap_or_rollback()
      end

      clock
    end)
  end

  defp unwrap_or_rollback({:ok, value}), do: value
  defp unwrap_or_rollback({:error, changeset}), do: Repo.rollback(changeset)

  @doc """
  Updates a clock.

  ## Examples

      iex> update_clock(clock, %{field: new_value})
      {:ok, %Clock{}}

      iex> update_clock(clock, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_clock(%Clock{} = clock, attrs) do
    clock
    |> Clock.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a clock.

  ## Examples

      iex> delete_clock(clock)
      {:ok, %Clock{}}

      iex> delete_clock(clock)
      {:error, %Ecto.Changeset{}}

  """
  def delete_clock(%Clock{} = clock) do
    Repo.delete(clock)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking clock changes.

  ## Examples

      iex> change_clock(clock)
      %Ecto.Changeset{data: %Clock{}}

  """
  def change_clock(%Clock{} = clock, attrs \\ %{}) do
    Clock.changeset(clock, attrs)
  end
end
