defmodule XinfengWeb.PageController do
  use XinfengWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
