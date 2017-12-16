defmodule ZX do

  def i(param) do
    IO.inspect(param)
  end

  def i(param, label) do
    IO.puts(label)
    IO.inspect(param)
  end

  def log(param) do
  end
  
end
