defmodule Xinfeng.Repo.Migrations.AddAdvertTable do
  use Ecto.Migration

  def change do
    create table(:adverts) do
      add :title, :string
      add :body, :text
      add :image_urls, {:array, :string}, default: []
      add :link, :string
      add :scheduled_at, :utc_datetime
      add :duration_minutes, :integer, default: 5, null: false

      add :user_id, references(:users, type: :string, on_delete: :delete_all), null: false

      timestamps()
    end
  end
end
