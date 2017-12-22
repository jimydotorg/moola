defmodule Moola.GDAXState do

  import Moola.Util

  def start_link do
    {:ok, pid} = Task.start_link(fn -> loop(%{}) end) |> ZX.i("starting GDAXState:")
    pid |> Process.register(Moola.GDAXState)
  end

  defp loop(map) do
    receive do
      {:get, symbol, caller} -> 
        symbol = symbol |> downcase |> atomize
        send(caller, Map.get(map, symbol))
        loop(map)
      {:put, symbol, value} ->
        symbol = symbol |> downcase |> atomize
        loop(Map.put(map, symbol, value)) 
    end
  end

  def put(symbol, state) do
    case Process.whereis(Moola.GDAXState) do
      nil -> start_link
      _ -> nil
    end

    send(Moola.GDAXState, {:put, symbol, state})
  end

  def get(symbol) do
    case Process.whereis(Moola.GDAXState) do
      nil -> start_link
      _ -> nil
    end

    send(Moola.GDAXState, {:get, symbol, self})
    receive do
      value -> value
    end
  end
end
