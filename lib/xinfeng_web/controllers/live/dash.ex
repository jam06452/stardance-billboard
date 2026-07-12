defmodule XinfengWeb.DashLive do
  use XinfengWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:form, to_form(%{"image_urls" => ["", "", ""]}))
      |> allow_upload(:images, accept: ~w(.jpg .jpeg .png .gif .webp), max_entries: 3)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto p-4">
      <form
        phx-change="validate"
        phx-submit="save"
        phx-drop-target={@uploads.images.ref}
        class="space-y-4"
      >
        <input
          type="hidden"
          name="timezone"
          id="timezone-input"
          phx-hook="LocalTimezone"
          value={@form[:timezone].value}
        />

        <fieldset class="fieldset">
          <legend class="fieldset-legend">Title</legend>
          <input
            type="text"
            name="title"
            value={@form[:title].value}
            class="input"
            placeholder="Type here"
            required
          />
          <p class="label">Mandatory</p>
        </fieldset>

        <textarea name="body" class="textarea" placeholder="Body"><%= @form[:body].value %></textarea>

        <input
          type="datetime-local"
          name="datetime"
          value={@form[:datetime].value}
          class="input"
          step="300"
          required
        />

        <div class="space-y-2">
          <p class="font-medium">Images (Up to 3 total, URLs or Uploads)</p>
          <.live_file_input upload={@uploads.images} class="file-input" />

          <%= for entry <- @uploads.images.entries do %>
            <div class="flex items-center gap-2 text-sm">
              <.live_img_preview entry={entry} class="h-10 w-10 object-cover" />
              <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref}>
                Cancel
              </button>
            </div>
          <% end %>

          <div class="flex flex-col gap-2">
            <%= for i <- 0..2 do %>
              <% urls = @form[:image_urls].value || []
              url_val = if is_map(urls), do: Map.get(urls, to_string(i)), else: Enum.at(urls, i) %>
              <input
                type="url"
                name={"image_urls[#{i}]"}
                value={url_val}
                class="input"
                placeholder="Image URL (Optional)"
              />
            <% end %>
          </div>
        </div>

        <label class="input validator">
          <svg class="h-[1em] opacity-50" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
            <g
              stroke-linejoin="round"
              stroke-linecap="round"
              stroke-width="2.5"
              fill="none"
              stroke="currentColor"
            >
              <path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"></path>
              <path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"></path>
            </g>
          </svg>
          <input
            type="url"
            name="link"
            required
            placeholder="https://stardance.hackclub.com/projects/"
            value={@form[:link].value || "https://stardance.hackclub.com/projects/"}
            pattern="^(https?://)?([a-zA-Z0-9]([a-zA-Z0-9\-].*[a-zA-Z0-9])?\.)+[a-zA-Z].*$"
            title="Must be valid URL"
          />
        </label>
        <p class="validator-hint">Must be valid URL</p>

        <button type="submit" class="btn btn-primary mt-4">Submit</button>
      </form>
    </div>
    """
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :images, ref)}
  end

  def handle_event("validate", params, socket) do
    {:noreply, assign(socket, :form, to_form(params))}
  end

  def handle_event("save", %{"timezone" => timezone, "datetime" => local_dt} = params, socket) do
    valid_urls =
      params["image_urls"]
      |> Map.values()
      |> Enum.reject(&(&1 == "" || is_nil(&1)))

    upload_count = length(socket.assigns.uploads.images.entries)

    if upload_count + length(valid_urls) > 3 do
      {:noreply, put_flash(socket, :error, "You can only provide a maximum of 3 images total.")}
    else
      _uploaded_files =
        consume_uploaded_entries(socket, :images, fn %{path: path}, _entry ->
          # Implementation for moving file to storage goes here
          {:ok, path}
        end)

      utc_datetime = to_utc(local_dt, timezone)

      {:noreply, put_flash(socket, :info, "Saved successfully at UTC: #{utc_datetime}")}
    end
  end

  defp to_utc(datetime_str, timezone) do
    with {:ok, naive} <- NaiveDateTime.from_iso8601(datetime_str <> ":00"),
         {:ok, datetime} <- DateTime.from_naive(naive, timezone) do
      DateTime.shift_zone!(datetime, "Etc/UTC")
    else
      _ -> nil
    end
  end
end
