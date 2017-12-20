defmodule MoolaWeb.Plugs.Logger do
  import Plug.Conn

  def init(default) do
    default
  end

  def call(%Plug.Conn{} = conn, default) do
    conn |> Moola.Log.record("http/" <> conn.method <> conn.request_path)
  end

end
