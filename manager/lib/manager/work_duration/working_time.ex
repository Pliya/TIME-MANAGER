defmodule Time_manager.WorkDuration.WorkingTime do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workingtime" do
    field :start, :utc_datetime
    field :end, :utc_datetime
    belongs_to :user, Time_manager.Account.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(working_time, attrs) do
    working_time
    |> cast(attrs, [:start, :end, :user_id])
    |> validate_required([:start, :end, :user_id])
    |> validate_start_before_end()
    |> foreign_key_constraint(:user_id)
  end

  defp validate_start_before_end(changeset) do
    start_time = get_field(changeset, :start)
    end_time = get_field(changeset, :end)

    cond do
      is_nil(start_time) or is_nil(end_time) ->
        changeset

      DateTime.compare(start_time, end_time) == :lt ->
        changeset

      true ->
        add_error(changeset, :end, "must be after start")
    end
  end
end
