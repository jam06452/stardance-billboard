defmodule Xinfeng.Repo.Migrations.RemoveTitleFromAdverts do
  use Ecto.Migration

  def change do
    alter table(:adverts) do
      remove :title
    end
  end
end
