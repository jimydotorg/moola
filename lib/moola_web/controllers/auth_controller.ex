defmodule MoolaWeb.AuthController do
  use MoolaWeb, :controller

  alias Moola.Auth
  alias Moola.Account
  alias Moola.ClientToken
  alias Moola.UserToken
  alias Moola.User

  action_fallback MoolaWeb.FallbackController

  def init(%Plug.Conn{} = conn, params) do

    case conn.assigns[:client_token] do
      %ClientToken{} = existing_token ->
        render_json(conn, %{clientToken: existing_token, now: DateTime.utc_now})

      _ ->
        remote_ip_string = conn.remote_ip |> Tuple.to_list |> Enum.join(".")
        params = params |> Map.put("creating_ip", remote_ip_string)

        with {:ok, %ClientToken{} = client_token} <- Auth.create_client_token(params) do
          render_json(conn, %{clientToken: client_token, now: DateTime.utc_now})
        end
    end
  end

  def login(%Plug.Conn{} = conn, %{} = params) do
    params = underscore(params)
    case Account.login(params) do
      {:ok, user, user_token} -> render_json(conn, %{currentUser: user, userToken: user_token}, [is_me: true])
      {:error, err} -> render_error(conn, err)
    end
  end

end
