defmodule MoolaWeb.GdaxController do
  use MoolaWeb, :controller

  alias Moola.Ticker
  alias Moola.GDAXQuery

  action_fallback MoolaWeb.FallbackController

  def show(%Plug.Conn{} = conn, %{"id" => "latency"}) do
    data = GDAXQuery.query_latency([])
    render_json(conn, %{gdaxLatency: data})
  end

  def show(%Plug.Conn{} = conn, %{"id" => symbol}) do
    data = GDAXQuery.query_ticks([symbol: symbol])
    render_json(conn, %{gdaxTicker: data})
  end

end