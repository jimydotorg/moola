defmodule Moola.GDAXState do

  import Moola.Util

  def start_link do
    with {:ok, pid} <- Task.start_link(fn -> loop(%{}) end) do
      pid |> Process.register(Moola.GDAXState)
      {:ok, pid}
    end
  end

  defp loop(map) do
    receive do
      {:get, symbol, caller} -> 
        symbol = symbol |> symbolize
        send(caller, Map.get(map, symbol))
        loop(map)
      {:put, symbol, values} ->
        symbol = symbol |> symbolize
        new_values = Map.get(map, symbol, %{}) |> Map.merge(values) 
        new_map = Map.put(map, symbol, new_values)
        loop(new_map) 
    end
  end

  def put(symbol, state) do
    send(Moola.GDAXState, {:put, symbol, state})
  end

  def get(symbol) do
    send(Moola.GDAXState, {:get, symbol, self()})
    receive do
      value -> value
    end
  end
end
