defmodule Xinfeng.Utils do
  def edit_devlog(body, images \\ []) do
    cookie = "_stardance_session_v3=" <> Application.get_env(:xinfeng, :stardance_cookie)
    devlog_url = Application.get_env(:xinfeng, :devlog_url)

    %{body: html} = Req.get!(devlog_url <> "/edit", headers: [{"cookie", cookie}])

    {:ok, document} = Floki.parse_document(html)
    [csrf_token] = Floki.attribute(document, "meta[name='csrf-token']", "content")

    existing_image_ids =
      document
      |> Floki.find("input[name='remove_attachment_ids[]']")
      |> Floki.attribute("value")

    remove_attachments =
      if length(images) > 0 do
        Enum.map(existing_image_ids, fn id ->
          {:"remove_attachment_ids[]", id}
        end)
      else
        []
      end

    downloaded_attachments =
      images
      |> Task.async_stream(fn url ->
        %{body: image_binary} = Req.get!(url)
        filename = url |> URI.parse() |> Map.get(:path) |> Path.basename()
        {:"post_devlog[attachments][]", {image_binary, filename: filename}}
      end)
      |> Enum.map(fn {:ok, result} -> result end)

    empty_slots_needed = max(0, 3 - length(images))
    empty_attachments = List.duplicate({:"post_devlog[attachments][]", ""}, empty_slots_needed)

    multipart_data =
      [
        {:_method, "patch"},
        {:authenticity_token, csrf_token},
        {:"post_devlog[body]", body}
      ] ++ remove_attachments ++ downloaded_attachments ++ empty_attachments

    Req.post!(devlog_url,
      form_multipart: multipart_data,
      headers: [{"cookie", cookie}],
      redirect: false
    )
  end
end
