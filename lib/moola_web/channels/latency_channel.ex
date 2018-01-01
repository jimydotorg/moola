defmodule MoolaWeb.LatencyChannel do
  use MoolaWeb, :channel

  def join("latency:gdax", params, socket) do
    {:ok, socket}
  end

end