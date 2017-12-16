defmodule ZXUtil do

  @doc """
  Filter out elements of map for which fun is not true. Unlike Enum.filter, outputs a map when given a map as input
  """
  def filter(%{} = map, fun) do
    Enum.reduce map, %{}, 
    fn({k,v}, acc) -> 
      if fun.({k,v}) do
        Map.put(acc, k, v)
      else
        acc
      end
    end      
  end

  def filter(enum, fun) do
    Enum.filter(enum, fun)
  end

  def filter_nils(enum) do
    case enum do
      %{} = map -> filter(map, fn({k,v}) -> v != nil end)
      other -> Enum.filter(other, fn(el) -> el != nil end)
    end
  end

  @doc """
  Atomize string keys
  """
  def atomize(%{} = map) do
    for {key, val} <- map, into: %{} do
      {atomize(key), val}
    end
  end

  def atomize(list) when is_list(list) do
    list |> Enum.map(&atomize/1)
  end

  def atomize(string) when is_bitstring(string), do: String.to_atom(string)
  def atomize(atom) when is_atom(atom), do: atom

  @doc """
  Stringify atom keys
  """
  def stringify(%{} = map) do
    for {key, val} <- map, into: %{} do
      {stringify(key), val}
    end
  end

  def stringify(list) when is_list(list) do
    list |> Enum.map(&stringify/1)
  end

  def stringify(atom) when is_atom(atom), do: Atom.to_string(atom)
  def stringify(string) when is_bitstring(string), do: string

  def takeem(%{} = map, keys) when is_list(keys), do: map |> Map.take(atomize(keys) ++ stringify(keys))
  def dropem(%{} = map, keys) when is_list(keys), do: map |> Map.drop(atomize(keys) ++ stringify(keys))

  def upcase(atom_or_string), do: atom_or_string |> stringify |> String.upcase
  def downcase(atom_or_string), do: atom_or_string |> stringify |> String.downcase

  @doc """
  Convert CamelCase keys to snake_case
  """
  def underscore(%{} = map) do
    Enum.reduce(map, %{}, fn({k,v}, acc) -> Map.put(acc, ZXUtil.underscore(k), v) end)
  end

  @doc """
  Convert snake_case keys to CamelCase 
  """
  def camelize(%{} = map) do
    Enum.reduce(map, %{}, fn({k,v}, acc) -> Map.put(acc, ZXUtil.camelize(k), v) end)
  end

  @doc """
  Access nested attributes via keypath
  """
  def get_path(%{} = map, keypath) when is_list(keypath) do 
    access_keys = keypath |> Enum.map(fn(k) -> Access.key(k) end)
    try do
      Kernel.get_in(map, access_keys)
    rescue
      _ -> nil
    end
  end

  def get_path(%{} = map, key) do
    get_path(map, [key]) 
  end

  @doc """
  Conditionally set key based on truthiness of predicate
  """
  def put_if(%{} = map, key, predicate, true_val, false_val \\ nil) do
    if predicate do
      map |> Map.put(key, true_val)
    else
      if false_val do
        map |> Map.put(key, false_val)
      else
        map
      end
    end
  end
 
  @doc """
  Remove all non-numerals from string
  """
  def filter_non_numeric(str) do
    String.replace(str, ~r/[^0-9]/, "")
  end

  def md5(str) when is_bitstring(str) do
    :crypto.hash(:md5, str) |> Base.encode16
  end

  def decapitalize(string) do
    String.downcase(String.slice(string, 0,1)) <> String.slice(string, 1..-1)
  end

  def underscore(string) when is_bitstring(string) do
    Macro.underscore(string)
  end

  def camelize(string) when is_bitstring(string) do
    Macro.camelize(string) |> decapitalize
  end

end

