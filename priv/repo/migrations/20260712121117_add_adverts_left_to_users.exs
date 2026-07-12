defmodule Xinfeng.Repo.Migrations.AddAdvertsLeftToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :adverts_left, :integer, default: 1, null: false
    end
  end
end
