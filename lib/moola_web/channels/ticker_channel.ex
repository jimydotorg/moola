defmodule MoolaWeb.TickerChannel do
  use MoolaWeb, :channel

  def join("ticker:gdax", params, socket) do
    {:ok, socket}
  end

  def join("ticker:coinbase", params, socket) do
    {:ok, socket}
  end

end