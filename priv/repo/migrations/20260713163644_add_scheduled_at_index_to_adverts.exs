defmodule Xinfeng.Repo.Migrations.AddScheduledAtIndexToAdverts do
  use Ecto.Migration

  def change do
    create index(:adverts, [:scheduled_at])
  end
end
