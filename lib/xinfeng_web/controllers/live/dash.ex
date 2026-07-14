defmodule XinfengWeb.DashLive do
  use XinfengWeb, :live_view

  alias Xinfeng.Accounts.Advert
  alias Xinfeng.Accounts.User
  alias Xinfeng.Repo
  alias Ecto.Multi
  import Ecto.Query

  def mount(_params, session, socket) do
    user_id = session["user_id"]

    adverts = list_upcoming_adverts()

    socket =
      socket
      |> assign(:current_user, user_id)
      |> assign(:timezone, "UTC")
      |> assign(:adverts, adverts)
      |> assign(:form, to_form(%{"image_urls" => ["", "", ""]}))
      |> allow_upload(:images,
        accept: ~w(.jpg .jpeg .png .gif .webp),
        max_entries: 3,
        auto_upload: true,
        max_file_size: 209_715_200
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.flash kind={:info} flash={@flash} />
    <.flash kind={:error} flash={@flash} />
    <div class="flex flex-col lg:flex-row gap-12 max-w-7xl mx-auto p-8">
      <div class="flex-1 max-w-2xl">
        <div class="text-xl font-semibold mb-6 text-base-content flex items-center justify-between">
          <span>Upcoming Adverts</span>
          <.link href="/signout" class="btn btn-ghost btn-sm text-base-content/70 hover:text-error">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="w-4 h-4"
            >
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
              <polyline points="16 17 21 12 16 7" />
              <line x1="21" y1="12" x2="9" y2="12" />
            </svg>
            <span>Sign out</span>
          </.link>
        </div>

        <div class="flex flex-col gap-6">
          <%= for advert <- @adverts do %>
            <div class="bg-[#0b0e14] border border-[#2f3336] rounded-xl overflow-hidden text-[#e7e9ea] font-sans">
              
    <!-- Scheduled At Badge (Skips if time has passed) -->
              <%= if DateTime.compare(advert.scheduled_at, DateTime.utc_now()) == :gt do %>
                <div class="px-4 pt-3 text-[14px] text-[#71767b] flex items-center gap-1.5">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    class="w-4 h-4"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M12 2.25c-5.385 0-9.75 4.365-9.75 9.75s4.365 9.75 9.75 9.75 9.75-4.365 9.75-9.75S17.385 2.25 12 2.25zM12.75 6a.75.75 0 00-1.5 0v6c0 .414.336.75.75.75h4.5a.75.75 0 000-1.5h-3.75V6z"
                      clip-rule="evenodd"
                    />
                  </svg>
                  {Calendar.strftime(advert.scheduled_at, "%b %d, %Y at %I:%M %p UTC")}
                </div>
              <% end %>
              
    <!-- Body -->
              <div class="px-4 pt-3 pb-3 text-[15px] leading-snug whitespace-pre-wrap">
                {if advert.body && advert.body != "", do: advert.body, else: ""}
              </div>

              <%= if advert.image_urls != [] do %>
                <div class="px-4 pb-4">
                  <!-- Dynamic grid: 1 column for 1 image, 2 columns for multiple -->
                  <div class={[
                    "rounded-2xl border border-[#2f3336] overflow-hidden bg-white grid gap-0.5",
                    length(advert.image_urls) == 1 && "grid-cols-1",
                    length(advert.image_urls) > 1 && "grid-cols-2"
                  ]}>
                    <%= for url <- advert.image_urls do %>
                      <img
                        src={url}
                        class="w-full h-full object-cover max-h-[500px]"
                      />
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
      <div class="w-full lg:w-96 shrink-0 bg-base-100 p-6 rounded-box shadow-lg">
        <form
          id="advert-form"
          phx-hook="LocalTimezone"
          phx-change="validate"
          phx-submit="save"
          phx-drop-target={@uploads.images.ref}
          class="space-y-4"
        >
          <fieldset class="fieldset">
            <legend class="fieldset-legend">Body</legend>
            <textarea
              name="body"
              class="textarea h-24 w-full"
              placeholder="Type your advert body here"
              required
            ><%= @form[:body].value %></textarea>
          </fieldset>

          <div class="flex flex-col gap-6">
            <div>
              <label class="label"><span class="label-text font-medium">Date</span></label>

              <input
                type="hidden"
                id="hidden_date"
                name="schedule_date"
                value={@form.params["schedule_date"]}
              />

              <button
                type="button"
                popovertarget="cally-popover1"
                class="input input-bordered w-full flex items-center text-left"
                id="cally1"
                style="anchor-name:--cally1"
              >
                {if @form.params["schedule_date"] in [nil, ""],
                  do: "Pick a date",
                  else: @form.params["schedule_date"]}
              </button>

              <div id="cally-wrapper" phx-update="ignore">
                <div
                  popover
                  id="cally-popover1"
                  class="dropdown bg-base-100 rounded-box shadow-lg"
                  style="position-anchor:--cally1"
                >
                  <calendar-date
                    class="cally"
                    onchange="
                      document.getElementById('cally1').innerText = this.value;
                      let hidden = document.getElementById('hidden_date');
                      hidden.value = this.value;
                      hidden.dispatchEvent(new Event('input', {bubbles: true}));
                    "
                  >
                    <svg
                      aria-label="Previous"
                      class="fill-current size-4"
                      slot="previous"
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 24 24"
                    >
                      <path d="M15.75 19.5 8.25 12l7.5-7.5"></path>
                    </svg>
                    <svg
                      aria-label="Next"
                      class="fill-current size-4"
                      slot="next"
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 24 24"
                    >
                      <path d="m8.25 4.5 7.5 7.5-7.5 7.5"></path>
                    </svg>
                    <calendar-month></calendar-month>
                  </calendar-date>
                </div>
              </div>
            </div>

            <div>
              <% mins_str = @form.params["schedule_time_minutes"] || "720"
              {total_mins, _} = Integer.parse(to_string(mins_str))
              hours = div(total_mins, 60) |> to_string() |> String.pad_leading(2, "0")
              mins = rem(total_mins, 60) |> to_string() |> String.pad_leading(2, "0")
              display_time = "#{hours}:#{mins}" %>
              <label class="label">
                <span class="label-text font-medium">Time</span>
                <span class="label-text-alt font-bold text-lg text-primary">{display_time}</span>
              </label>
              <input
                type="range"
                name="schedule_time_minutes"
                min="0"
                max="1435"
                step="5"
                value={mins_str}
                class="range range-primary w-full"
              />
            </div>

            <p :for={msg <- @form[:scheduled_at].errors} class="text-error text-sm">
              {translate_error(msg)}
            </p>
          </div>

          <div class="space-y-2">
            <p class="font-medium">Images (Up to 3 total, URLs or Uploads)</p>
            <.live_file_input upload={@uploads.images} class="file-input w-full" />

            <%= for entry <- @uploads.images.entries do %>
              <div class="flex items-center gap-4 text-sm bg-base-200 p-2 rounded-lg">
                <.live_img_preview entry={entry} class="h-12 w-12 object-cover rounded" />
                <div class="flex-1">
                  <progress
                    value={entry.progress}
                    max="100"
                    class="progress progress-primary w-full"
                  >
                  </progress>
                  <div class="text-xs text-base-content/70 mt-1">
                    {if entry.done?, do: "Upload complete", else: "#{entry.progress}% uploaded"}
                  </div>
                  <%= for err <- upload_errors(@uploads.images, entry) do %>
                    <p class="text-error font-bold mt-1">
                      {if err == :too_large, do: "File exceeds 200MB limit", else: "Upload failed"}
                    </p>
                  <% end %>
                </div>
                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-value-ref={entry.ref}
                  class="text-error hover:underline shrink-0"
                >
                  Cancel
                </button>
              </div>
            <% end %>

            <div class="flex flex-col gap-2">
              <%= for i <- 0..2 do %>
                <% urls = @form.params["image_urls"] || @form[:image_urls].value || []
                url_val = if is_map(urls), do: Map.get(urls, to_string(i)), else: Enum.at(urls, i) %>
                <input
                  type="url"
                  name={"image_urls[#{i}]"}
                  value={url_val}
                  class="input w-full"
                  placeholder="Image URL (Optional)"
                />
              <% end %>
            </div>
            <p :for={msg <- @form[:image_urls].errors} class="text-error text-sm mt-1">
              {translate_error(msg)}
            </p>
          </div>

          <fieldset class="fieldset">
            <legend class="fieldset-legend">Link to stardance project</legend>
            <label class="input validator w-full">
              <input
                type="url"
                name="link"
                class="w-full"
                placeholder="https://..."
                value={@form[:link].value}
                pattern="^(https?://)?([a-zA-Z0-9]([a-zA-Z0-9\-].*[a-zA-Z0-9])?\.)+[a-zA-Z].*$"
                title="Must be valid URL"
              />
            </label>
            <p class="validator-hint">Must be valid URL</p>
          </fieldset>

          <button type="submit" class="btn btn-primary mt-4 w-full">Save Advert</button>
        </form>
      </div>
    </div>
    """
  end

  def handle_event("set_timezone", %{"timezone" => tz}, socket) do
    {:noreply, assign(socket, :timezone, tz)}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :images, ref)}
  end

  def handle_event("validate", params, socket) do
    {:noreply, assign(socket, :form, to_form(params))}
  end

  def handle_event("save", params, socket) do
    user = Repo.get!(User, socket.assigns.current_user)

    if user.adverts_left <= 0 do
      {:noreply,
       socket
       |> put_flash(:error, "Ran out of adverts")
       |> push_navigate(to: "/dash")}
    else
      {total_mins, _} = Integer.parse(params["schedule_time_minutes"] || "720")
      hours = div(total_mins, 60) |> to_string() |> String.pad_leading(2, "0")
      mins = rem(total_mins, 60) |> to_string() |> String.pad_leading(2, "0")

      local_datetime_str = "#{params["schedule_date"]}T#{hours}:#{mins}"
      scheduled_at = to_utc(local_datetime_str, socket.assigns.timezone)

      if scheduled_at && overlapping_ad?(scheduled_at) do
        attrs = %{
          "body" => params["body"],
          "link" => params["link"],
          "image_urls" => [],
          "scheduled_at" => scheduled_at,
          "user_id" => socket.assigns.current_user
        }

        changeset =
          %Advert{}
          |> Advert.changeset(attrs)
          |> Ecto.Changeset.add_error(
            :scheduled_at,
            "overlaps with another advert. Please pick a different time."
          )

        form = to_form(changeset |> Map.put(:params, params))

        {:noreply,
         socket
         |> put_flash(:error, "Could not save advert: Time overlaps with an existing advert.")
         |> assign(:form, form)}
      else
        valid_text_urls =
          (params["image_urls"] || %{})
          |> Map.values()
          |> Enum.reject(&(&1 == "" || is_nil(&1)))

        uploaded_urls =
          consume_uploaded_entries(socket, :images, fn %{path: path}, entry ->
            api_key = Application.get_env(:xinfeng, :hackclub_cdn_key)
            file_binary = File.read!(path)

            ext = Path.extname(entry.client_name)
            random_filename = Ecto.UUID.generate() <> ext

            response =
              Req.post!("https://cdn.hackclub.com/api/v4/upload",
                auth: {:bearer, api_key},
                form_multipart: [
                  file: {file_binary, filename: random_filename, content_type: entry.client_type}
                ]
              )

            if response.status in 200..299 do
              {:ok, response.body["url"]}
            else
              require Logger
              Logger.error("CDN Upload Failed: #{inspect(response.body)}")
              {:postpone, "CDN Upload Failed"}
            end
          end)

        all_image_urls = valid_text_urls ++ uploaded_urls

        attrs = %{
          "body" => params["body"],
          "link" => params["link"],
          "image_urls" => all_image_urls,
          "scheduled_at" => scheduled_at,
          "user_id" => socket.assigns.current_user
        }

        changeset = Advert.changeset(%Advert{}, attrs)
        user_changeset = Ecto.Changeset.change(user, adverts_left: user.adverts_left - 1)

        multi =
          Multi.new()
          |> Multi.insert(:advert, changeset)
          |> Multi.update(:user, user_changeset)

        case Repo.transaction(multi) do
          {:ok, _result} ->
            {:noreply,
             socket
             |> put_flash(:info, "Successfully saved")
             |> push_navigate(to: "/dash")}

          {:error, _failed_operation, %Ecto.Changeset{} = error_changeset, _changes_so_far} ->
            form = to_form(error_changeset |> Map.put(:params, params))

            {:noreply,
             socket
             |> put_flash(:error, "Failed to save advert. Please check the form for errors.")
             |> assign(:form, form)}
        end
      end
    end
  end

  defp list_upcoming_adverts do
    now = DateTime.utc_now()

    from(a in Advert,
      where: a.scheduled_at >= ^now,
      order_by: [asc: a.scheduled_at]
    )
    |> Repo.all()
  end

  defp overlapping_ad?(scheduled_at) do
    duration = %Advert{}.duration_minutes
    end_time = DateTime.add(scheduled_at, duration, :minute)

    from(a in Advert,
      where: a.scheduled_at < ^end_time,
      where:
        fragment("? + ? * interval '1 minute'", a.scheduled_at, a.duration_minutes) >
          ^scheduled_at
    )
    |> Repo.exists?()
  end

  defp to_utc(datetime_str, timezone) when datetime_str not in ["", nil] do
    if String.starts_with?(datetime_str, "T") do
      nil
    else
      iso_str =
        if String.length(datetime_str) == 16, do: datetime_str <> ":00", else: datetime_str

      with {:ok, naive} <- NaiveDateTime.from_iso8601(iso_str),
           {:ok, datetime} <- DateTime.from_naive(naive, timezone) do
        DateTime.shift_zone!(datetime, "Etc/UTC")
      else
        _ -> nil
      end
    end
  end

  defp to_utc(_, _), do: nil
end
