defmodule Xinfeng.Repo do
  use Ecto.Repo,
    otp_app: :xinfeng,
    adapter: Ecto.Adapters.Postgres
end
