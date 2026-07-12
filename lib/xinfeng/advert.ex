defmodule Xinfeng.Accounts.Advert do
  use Ecto.Schema
  import Ecto.Changeset

  schema "adverts" do
    field :title, :string
    field :body, :string
    field :image_urls, {:array, :string}, default: []
    field :link, :string
    field :scheduled_at, :utc_datetime
    field :duration_minutes, :integer, default: 5

    belongs_to :user, Xinfeng.Accounts.User, type: :string

    timestamps()
  end

  def changeset(advert, attrs) do
    advert
    |> cast(attrs, [:title, :body, :image_urls, :link, :user_id, :scheduled_at, :duration_minutes])
    |> validate_required([:title, :user_id, :scheduled_at])
    |> validate_length(:image_urls, max: 3, message: "can have at most 3 images")
    |> validate_number(:duration_minutes, greater_than: 0)
    |> foreign_key_constraint(:user_id)
  end
end
