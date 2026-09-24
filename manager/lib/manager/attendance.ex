defmodule Time_manager.Attendance do
  @moduledoc """
  The Attendance context.
  """

  import Ecto.Query, warn: false
  alias Time_manager.Repo

  alias Time_manager.Attendance.Clock

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
    last_status =
      from(c in Clock,
        where: c.user_id == ^user_id,
        order_by: [desc: c.time],
        limit: 1,
        select: c.status
      )
      |> Repo.one()

    new_status = last_status == true

    %Clock{user_id: user_id, status: new_status, time: DateTime.utc_now()}
    |> Clock.changeset(%{})
    |> Repo.insert()
  end

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
