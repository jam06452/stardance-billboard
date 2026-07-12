defmodule Xinfeng.AuthController do
  use XinfengWeb, :controller

  def on_success(conn, _auth) do
    conn
    |> put_flash(:info, "Successfully authenticated")
    |> redirect(to: ~p"/")
  end

  def on_failure(conn, _reason) do
    conn
    |> put_flash(:error, "Authentication failed")
    |> redirect(to: ~p"/")
  end
end
