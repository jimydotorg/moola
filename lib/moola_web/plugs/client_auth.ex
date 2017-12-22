defmodule MoolaWeb.Plugs.ExtractClient do
  import Plug.Conn
  alias Moola.Auth

  def init(default) do
    default
  end

  def call(%Plug.Conn{} = conn, default) do
    case get_req_header(conn, "client-token") do
      [token_string] ->
        process(conn, token_string)
      _ -> 
        conn = fetch_query_params(conn)
        case conn.query_params["ct"] do
          nil -> conn
          query_ct -> 
            process(conn, query_ct)
        end
    end
  end

  defp process(conn, token_string) do
    with %Moola.ClientToken{} = client_token <- Auth.get_client_token(token_string) do
      Task.start(fn -> Auth.update_client_token(client_token, %{last_active_at: DateTime.utc_now}) end)
      conn |> Plug.Conn.assign(:client_token, client_token)
    else
      _ -> conn
    end
  end

end

defmodule MoolaWeb.Plugs.RequireClient do
  import Plug.Conn
  alias Moola.Auth

  def init(default) do
    default
  end

  def call(%Plug.Conn{} = conn, default) do
    case conn.assigns[:client_token] do 
      %Moola.ClientToken{} ->
        conn
      _ ->
        conn 
        |> put_resp_header("content-type", "application/json; charset=utf-8")
        |> send_resp(401, Poison.encode!(%{error: "unauthorized"}))
        |> halt
    end
  end

end