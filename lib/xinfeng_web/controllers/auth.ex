defmodule XinfengWeb.AuthController do
  use XinfengWeb, :controller

  def on_success(conn, auth) do
    user_attrs = %{
      id: auth.uid,
      name: auth.name,
      email: auth.email,
      slack_id: auth.slack_id
    }

    auth_result =
      case Xinfeng.Repo.get(Xinfeng.Accounts.User, auth.uid) do
        nil ->
          # New user: insert
          %Xinfeng.Accounts.User{}
          |> Xinfeng.Accounts.User.changeset(user_attrs)
          |> Xinfeng.Repo.insert()

        user ->
          user
          |> Xinfeng.Accounts.User.changeset(user_attrs)
          |> Xinfeng.Repo.update()
      end

    case auth_result do
      {:ok, user} ->
        conn
        |> configure_session(renew: true)
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Successfully authenticated")
        |> redirect(to: ~p"/dash")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to authenticate user")
        |> redirect(to: ~p"/")
    end
  end

  def on_failure(conn, _reason) do
    conn
    |> put_flash(:error, "Authentication failed")
    |> redirect(to: ~p"/")
  end

  def signout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/")
  end
end
