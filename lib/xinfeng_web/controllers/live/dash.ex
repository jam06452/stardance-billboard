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
    <div class="relative min-h-screen overflow-hidden bg-[#120b16] text-white">
      <div class="absolute inset-0 bg-gradient-to-br from-[#1b1324] via-[#120b16] to-[#0d0912]"></div>

      <img
        src="https://stardance.hackclub.com/assets/landing/hero/earth-1bcc8966.png"
        class="absolute top-24 left-1/2 -translate-x-1/2 w-20 pointer-events-none select-none"
        draggable="false"
      />

      <img
        src="https://stardance.hackclub.com/assets/landing/hero/moon-6cc9fac1.png"
        class="absolute top-48 left-[54%] w-24 pointer-events-none select-none"
        draggable="false"
      />

      <img
        src="https://stardance.hackclub.com/assets/landing/hero/nasa-hero-e6195581.png"
        class="absolute -bottom-40 -right-24 w-[550px] lg:w-[760px] pointer-events-none select-none"
        draggable="false"
      />

      <img
        src="https://stardance.hackclub.com/assets/landing/hero/star-character-e6aa34d1.png"
        class="absolute top-8 left-6 w-10 -rotate-12"
        draggable="false"
      />

      <img
        src="https://stardance.hackclub.com/assets/landing/hero/star-character-e6aa34d1.png"
        class="absolute top-1/3 right-10 w-12 rotate-12"
        draggable="false"
      />

      <div class="relative z-10 min-h-screen px-6 py-8 lg:px-20 lg:py-12">
        <div class="max-w-7xl mx-auto flex flex-col lg:flex-row gap-12">
          <%!-- Left column: Advert list --%>
          <div class="flex-1 max-w-2xl">
            <div class="flex items-center justify-between mb-8">
              <h2 class="text-2xl lg:text-3xl font-extrabold drop-shadow-[0_0_20px_rgba(255,255,255,0.2)]">
                Upcoming Adverts
              </h2>
              <.link
                href="/signout"
                class="inline-flex items-center gap-2 rounded-full border border-white/20 px-5 py-2 text-sm font-medium text-white/70 transition-all hover:border-red-400/50 hover:text-red-300 hover:bg-red-400/10"
              >
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
                <div class="bg-white/5 backdrop-blur-sm border border-white/10 rounded-2xl overflow-hidden text-gray-200 font-sans transition-shadow hover:shadow-[0_0_30px_rgba(255,255,255,0.05)]">
                  <%= if DateTime.compare(advert.scheduled_at, DateTime.utc_now()) == :gt do %>
                    <div class="px-5 pt-4 text-sm text-white/50 flex items-center gap-2">
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
                      {format_local_time(advert.scheduled_at, @timezone)}
                    </div>
                  <% end %>

                  <div class="px-5 pt-3 pb-3 text-[15px] leading-snug whitespace-pre-wrap">
                    {if advert.body && advert.body != "", do: advert.body, else: ""}
                  </div>

                  <%= if advert.image_urls != [] do %>
                    <div class="px-5 pb-5">
                      <div class={[
                        "rounded-2xl border border-white/10 overflow-hidden bg-white/10 grid gap-0.5",
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

          <%!-- Right column: Form --%>
          <div class="w-full lg:w-96 shrink-0">
            <div class="sticky top-8 bg-white/5 backdrop-blur-md border border-white/10 rounded-2xl p-6 shadow-[0_0_40px_rgba(255,255,255,0.03)]">
              <h3 class="text-lg font-bold mb-6 text-white/90">Create Advert</h3>

              <form
                id="advert-form"
                phx-hook="LocalTimezone"
                phx-change="validate"
                phx-submit="save"
                phx-drop-target={@uploads.images.ref}
                class="space-y-5"
              >
                <div>
                  <label class="block text-sm font-medium text-white/70 mb-2">Body</label>
                  <textarea
                    name="body"
                    class="w-full h-24 rounded-xl bg-white/5 border border-white/10 px-4 py-3 text-sm text-white placeholder-white/30 focus:outline-none focus:ring-2 focus:ring-white/20 focus:border-white/20 transition-all resize-none"
                    placeholder="Type your advert body here"
                    required
                  ><%= @form[:body].value %></textarea>
                </div>

                <div class="flex flex-col gap-5">
                  <div>
                    <label class="block text-sm font-medium text-white/70 mb-2">Date</label>

                    <input
                      type="hidden"
                      id="hidden_date"
                      name="schedule_date"
                      value={@form.params["schedule_date"]}
                    />

                    <button
                      type="button"
                      popovertarget="cally-popover1"
                      class="w-full flex items-center text-left rounded-xl bg-white/5 border border-white/10 px-4 py-3 text-sm text-white transition-all hover:bg-white/10"
                      id="cally1"
                    >
                      {if @form.params["schedule_date"] in [nil, ""],
                        do: "Pick a date",
                        else: @form.params["schedule_date"]}
                    </button>

                    <div id="cally-wrapper" phx-update="ignore">
                      <div
                        popover="auto"
                        id="cally-popover1"
                        class="m-auto rounded-xl bg-[#1b1324] border border-white/10 shadow-2xl p-3"
                      >
                        <calendar-date
                          id="cally-calendar"
                          class="cally"
                          phx-hook=".CallyPicker"
                          min={Date.utc_today() |> Date.to_iso8601()}
                          value={@form.params["schedule_date"] || ""}
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
                    <div class="flex items-center justify-between mb-2">
                      <span class="text-sm font-medium text-white/70">Time</span>
                      <span class="text-lg font-bold text-white drop-shadow-[0_0_15px_rgba(255,255,255,0.3)]">
                        {display_time}
                      </span>
                    </div>
                    <input
                      type="range"
                      name="schedule_time_minutes"
                      min="0"
                      max="1435"
                      step="5"
                      value={mins_str}
                      class="w-full h-2 rounded-full appearance-none bg-white/10 accent-white cursor-pointer [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-5 [&::-webkit-slider-thumb]:h-5 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-white [&::-webkit-slider-thumb]:shadow-[0_0_10px_rgba(255,255,255,0.4)] [&::-webkit-slider-thumb]:cursor-pointer [&::-webkit-slider-thumb]:transition-transform [&::-webkit-slider-thumb]:hover:scale-110"
                    />
                  </div>

                  <p :for={msg <- @form[:scheduled_at].errors} class="text-red-400 text-sm">
                    {translate_error(msg)}
                  </p>
                </div>

                <script :type={Phoenix.LiveView.ColocatedHook} name=".CallyPicker">
                  export default {
                    mounted() {
                      this.el.addEventListener("change", () => {
                        const value = this.el.value;
                        const button = document.getElementById("cally1");
                        const hidden = document.getElementById("hidden_date");
                        if (button) button.innerText = value || "Pick a date";
                        if (hidden) {
                          hidden.value = value;
                          hidden.dispatchEvent(new Event("input", { bubbles: true }));
                        }
                        const popover = document.getElementById("cally-popover1");
                        if (popover && typeof popover.hidePopover === "function") {
                          popover.hidePopover();
                        }
                      });
                    }
                  }
                </script>

                <div class="space-y-3">
                  <p class="text-sm font-medium text-white/70">
                    Images (Up to 3 total, URLs or Uploads)
                  </p>
                  <label class="block w-full rounded-xl bg-white/5 border border-dashed border-white/20 px-4 py-3 text-sm text-white/50 text-center cursor-pointer transition-all hover:bg-white/10 hover:border-white/30">
                    <span>Click to upload or drag files</span>
                    <.live_file_input upload={@uploads.images} class="hidden" />
                  </label>

                  <%= for entry <- @uploads.images.entries do %>
                    <div class="flex items-center gap-3 text-sm bg-white/5 border border-white/10 p-3 rounded-xl">
                      <.live_img_preview entry={entry} class="h-14 w-14 object-cover rounded-lg" />
                      <div class="flex-1 min-w-0">
                        <div class="w-full h-2 rounded-full bg-white/10 overflow-hidden">
                          <div
                            class="h-full rounded-full bg-white/60 transition-all duration-300"
                            style={"width: #{entry.progress}%"}
                          >
                          </div>
                        </div>
                        <div class="text-xs text-white/40 mt-1">
                          {if entry.done?, do: "Upload complete", else: "#{entry.progress}% uploaded"}
                        </div>
                        <%= for err <- upload_errors(@uploads.images, entry) do %>
                          <p class="text-red-400 font-medium mt-1 text-xs">
                            {if err == :too_large,
                              do: "File exceeds 200MB limit",
                              else: "Upload failed"}
                          </p>
                        <% end %>
                      </div>
                      <button
                        type="button"
                        phx-click="cancel-upload"
                        phx-value-ref={entry.ref}
                        class="text-red-400 hover:text-red-300 text-sm font-medium shrink-0 transition-colors"
                      >
                        Cancel
                      </button>
                    </div>
                  <% end %>

                  <div class="flex flex-col gap-2">
                    <%= for i <- 0..2 do %>
                      <% urls = @form.params["image_urls"] || @form[:image_urls].value || []

                      url_val =
                        if is_map(urls), do: Map.get(urls, to_string(i)), else: Enum.at(urls, i) %>
                      <input
                        type="url"
                        name={"image_urls[#{i}]"}
                        value={url_val}
                        class="w-full rounded-xl bg-white/5 border border-white/10 px-4 py-3 text-sm text-white placeholder-white/30 focus:outline-none focus:ring-2 focus:ring-white/20 focus:border-white/20 transition-all"
                        placeholder="Image URL (Optional)"
                      />
                    <% end %>
                  </div>
                  <p :for={msg <- @form[:image_urls].errors} class="text-red-400 text-sm">
                    {translate_error(msg)}
                  </p>
                </div>

                <div>
                  <label class="block text-sm font-medium text-white/70 mb-2">
                    Link to stardance project
                  </label>
                  <input
                    type="url"
                    name="link"
                    class="w-full rounded-xl bg-white/5 border border-white/10 px-4 py-3 text-sm text-white placeholder-white/30 focus:outline-none focus:ring-2 focus:ring-white/20 focus:border-white/20 transition-all"
                    placeholder="https://..."
                    value={@form[:link].value}
                    pattern="^(https?://)?([a-zA-Z0-9]([a-zA-Z0-9\-].*[a-zA-Z0-9])?\.)+[a-zA-Z].*$"
                    title="Must be valid URL"
                  />
                  <p class="text-xs text-white/30 mt-1.5">Must be valid URL</p>
                </div>

                <button
                  type="submit"
                  class="w-full inline-flex items-center justify-center rounded-full bg-white px-8 py-3 text-base font-bold text-[#120b16] shadow-lg transition-all hover:scale-[1.02] hover:bg-gray-200 hover:shadow-[0_0_30px_rgba(255,255,255,0.2)]"
                >
                  Save Advert
                </button>
              </form>
            </div>
          </div>
        </div>
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

  defp format_local_time(%DateTime{} = utc_dt, timezone) do
    local_dt = DateTime.shift_zone!(utc_dt, timezone)
    Calendar.strftime(local_dt, "%b %d, %Y at %I:%M %p #{timezone}")
  end
end
