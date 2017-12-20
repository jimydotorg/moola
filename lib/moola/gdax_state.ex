defmodule Moola.GDAXState do

  def start_link do
    {:ok, pid} = Task.start_link(fn -> loop(%{}) end)
    pid |> Process.register(Moola.GDAXState)
  end

  defp loop(map) do
    receive do
      {:get, symbol, caller} -> 
        send(caller, Map.get(map, symbol))
        loop(map)
      {:put, symbol, value} ->
        loop(Map.put(map, symbol, value)) 
    end
  end

  def put(symbol, state) do
    send(Moola.GDAXState, {:put, symbol, state})
  end

  def get(symbol) do
    send(Moola.GDAXState, {:get, symbol, self})
    receive do
      value -> value
    end
  end
end
