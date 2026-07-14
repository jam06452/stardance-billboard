defmodule XinfengWeb.Plugs.AuthPlug do
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  def init(default), do: default

  def call(conn, _opts) do
    is_valid_session? = get_session(conn, :user_id) != nil

    current_path = conn.request_path

    case {is_valid_session?, current_path} do
      {true, "/dash"} ->
        conn

      {true, _other_path} ->
        conn
        |> redirect(to: "/dash")
        |> halt()

      {false, "/"} ->
        conn
        |> clear_session()

      {false, _other_path} ->
        conn
        |> clear_session()
        |> redirect(to: "/")
        |> halt()
    end
  end
end
