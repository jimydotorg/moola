defmodule Moola.Util do

  @doc """
  Converts camelCase to snake_case
  """
  def underscore(%{} = map), do: ZXUtil.underscore(map)
  def underscore(string) when is_bitstring(string), do: ZXUtil.underscore(string)
  def underscore(_), do: nil

  @doc """
  Converts snake_case to camelCase
  """
  def camelize(%{} = map), do: ZXUtil.camelize(map)
  def camelize(string) when is_bitstring(string), do: ZXUtil.camelize(string)
  def camelize(_), do: nil
  
  def get_path(%{} = map, keypath), do: ZXUtil.get_path(map, keypath)
  
  def atomize(el), do: ZXUtil.atomize(el)
  def stringify(el), do: ZXUtil.stringify(el)

  def upcase(el), do: ZXUtil.upcase(el)
  def downcase(el), do: ZXUtil.downcase(el)
  
  def symbolize(symbol_string) do
    symbol_string 
    |> downcase
    |> atomize
  end
  
end