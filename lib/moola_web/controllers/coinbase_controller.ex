defmodule MoolaWeb.CoinbaseController do
  use MoolaWeb, :controller

  alias Moola.Ticker
  alias Moola.CoinbaseQuery

  action_fallback MoolaWeb.FallbackController

  def index(%Plug.Conn{} = conn, %{} = params) do
    data = CoinbaseQuery.query_ticks([])
    render_json(conn, %{cbaseTicker: data})
  end

  def show(%Plug.Conn{} = conn, %{"id" => "latency"}) do
    data = CoinbaseQuery.query_ticks([])
    render_json(conn, %{cbaseTicker: data})
  end

  def show(%Plug.Conn{} = conn, %{"id" => symbol}) do
    data = CoinbaseQuery.query_ticks([symbol: symbol])
    render_json(conn, %{cbaseTicker: data})
  end

end