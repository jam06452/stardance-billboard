defmodule Xinfeng.Workers.AdvertPublisher do
  use Oban.Worker,
    queue: :default,
    max_attempts: 1,
    unique: [period: 60]

  import Ecto.Query, only: [from: 2]

  @impl true
  def perform(%Oban.Job{} = _job) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    window_start = DateTime.add(now, -5, :minute)

    adverts =
      from(a in Xinfeng.Accounts.Advert,
        where: a.scheduled_at >= ^window_start and a.scheduled_at <= ^now
      )
      |> Xinfeng.Repo.all()

    for advert <- adverts do
      Xinfeng.Utils.edit_devlog(advert.body, advert.image_urls)
    end

    :ok
  end
end
