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

    if adverts == [] do
      Xinfeng.Utils.edit_devlog(
        "Do you want to know how computers *actually* work? Do you want to remove the wool placed over your eyes by modern languages? Abstraction breeds ambiguity! Crawssembly is the first step to seeing clearly. The only assembly langiage made for education. (Now as fast as native C!)",
        [
          "https://cdn.hackclub.com/019f609d-d621-7c78-86ac-d9e21dec7b33/9f7adca7-f169-47ad-8f9c-3519032103a7.png"
        ],
        "https://stardance.hackclub.com/projects/8100"
      )
    else
      for advert <- adverts do
        Xinfeng.Utils.edit_devlog(advert.body, advert.image_urls, advert.link)
      end
    end

    :ok
  end
end
