defmodule Xinfeng.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "users" do
    field :name, :string
    field :email, :string
    field :slack_id, :string

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:id, :name, :email, :slack_id])
    |> validate_required([:id, :name, :email])
    |> unique_constraint(:email)
  end
end
