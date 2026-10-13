defmodule Time_manager.Account.Role do
  use Ecto.Schema

  schema "roles" do
    field :name, :string

    has_many :users, Time_manager.Account.User

    timestamps(type: :utc_datetime)
  end
end
