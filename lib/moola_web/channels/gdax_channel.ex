defmodule MoolaWeb.GDAXChannel do
  use MoolaWeb, :channel

  def join("gdax:realtime", params, socket) do
    {:ok, socket}
  end

end