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
          "https://cdn.hackclub.com/019f664b-7d26-728f-9e00-7c17cef7b930/c1081293-2a6d-4d5d-86ee-fdb58d9b7e0e.png"
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
