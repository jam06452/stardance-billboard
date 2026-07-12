defmodule Xinfeng.Repo.Migrations.ChangeUserIdToString do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE users DROP CONSTRAINT users_pkey"

    alter table(:users) do
      modify :id, :string, primary_key: true
    end
  end
end
