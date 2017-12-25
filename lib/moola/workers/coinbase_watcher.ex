defmodule Moola.CoinbaseWatcher do

  use GenServer
  alias Moola.CBase

  @period 15

  def start_link(), do: GenServer.start_link(__MODULE__, %{})

  def start! do
    case start_link() do
      {:ok, pid} -> pid
      _ -> nil
    end
  end

  def init(state) do
    Process.send_after(self(), :work, 500)
    {:ok, state}
  end

  def handle_info(:work, state) do
    Application.get_env(:moola, Moola.CoinbaseWatcher)[:product_ids]
    |> Enum.each(fn(symbol) -> CBase.retrieve_quote(symbol) end)

    Process.send_after(self(), :work, @period * 1000) 
    {:noreply, state} 
  end

end