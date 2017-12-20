defmodule MoolaWeb.Plugs.ExtractUser do
  import Plug.Conn
  alias Moola.Auth

  def init(default) do
    default
  end

  def call(%Plug.Conn{} = conn, default) do
    case get_req_header(conn, "user-token") do
      [token_string] ->
        process(conn, token_string)
      _ -> 
        conn = fetch_query_params(conn)
        case conn.query_params["ut"] do
          nil -> conn
          query_ut -> 
            process(conn, query_ut)
        end
    end
  end

  defp process(conn, token_string) do
    try do
      user_token = Auth.get_user_token!(token_string)
      conn
      |> Plug.Conn.assign(:current_user, user_token.user)
      |> Plug.Conn.assign(:user_token, user_token)
    rescue
      Ecto.NoResultsError -> conn
    end
  end

end

defmodule MoolaWeb.Plugs.RequireUser do
  import Plug.Conn
  alias Moola.Auth

  def init(default) do
    default
  end

  def call(%Plug.Conn{} = conn, default) do
    case conn.assigns[:current_user] do
      %Moola.User{} ->
        conn

      # If no current user
      _ -> 
        conn 
        |> put_resp_header("content-type", "application/json; charset=utf-8")
        |> send_resp(401, Poison.encode!(%{error: "unauthorized"}))
        |> halt
    end
  end

end
