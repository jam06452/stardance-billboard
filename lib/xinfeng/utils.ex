defmodule Xinfeng.Utils do
  @default_image "https://cdn.hackclub.com/019f6030-7ba5-7483-962f-8d1480cdbc09/17fe3dd4-741a-4862-822a-486ad8a8014f.png"

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

    final_images = if images == [], do: [@default_image], else: images

    remove_attachments =
      Enum.map(existing_image_ids, fn id ->
        {:"remove_attachment_ids[]", id}
      end)

    downloaded_attachments =
      final_images
      |> Task.async_stream(fn url ->
        %{body: image_binary} = Req.get!(url)
        filename = url |> URI.parse() |> Map.get(:path) |> Path.basename()
        {:"post_devlog[attachments][]", {image_binary, filename: filename}}
      end)
      |> Enum.map(fn {:ok, result} -> result end)

    empty_slots_needed = max(0, 3 - length(final_images))
    empty_attachments = List.duplicate({:"post_devlog[attachments][]", ""}, empty_slots_needed)

    multipart_data =
      [
        {:_method, "patch"},
        {:authenticity_token, csrf_token},
        {:"post_devlog[body]",
         body <>
           "\n\nIf you want an awesome advertaisement like this, visit https://billboard.jam06452.uk"}
      ] ++ remove_attachments ++ downloaded_attachments ++ empty_attachments

    Req.post!(devlog_url,
      form_multipart: multipart_data,
      headers: [{"cookie", cookie}],
      redirect: false
    )
  end
end
