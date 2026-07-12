defmodule Xinfeng.AuthController do
  use XinfengWeb, :controller

  def on_success(conn, auth) do
    user_attrs = %{
      id: auth.uid,
      name: auth.name,
      email: auth.email,
      slack_id: auth.slack_id
    }

    case %Xinfeng.Accounts.User{}
         |> Xinfeng.Accounts.User.changeset(user_attrs)
         |> Xinfeng.Repo.insert() do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Successfully authenticated")
        |> redirect(to: ~p"/")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to create user")
        |> redirect(to: ~p"/")
    end
  end

  def on_failure(conn, _reason) do
    conn
    |> put_flash(:error, "Authentication failed")
    |> redirect(to: ~p"/")
  end
end
