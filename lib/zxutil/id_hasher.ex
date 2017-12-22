defmodule ZXUtil.IdHasher do

  @alphabet "123456789abcdefghjklmnopqrstuvwxyz"
  @coder Hashids.new(alphabet: @alphabet)

  def hashid(ids) when is_list(ids) do
    Hashids.encode(@coder, ids)
  end

  def hashid(id) when id > 0, do: hashid([id])
  def hashid(id), do: nil

  def dehash_list(data) do
    Hashids.decode(@coder, data)
  end

  def dehashid(data) do
    case dehash_list(data) do
      {:ok, [0]} -> nil
      {:ok, [id]} -> id
      _ -> nil
    end
  end

  @callback id() :: Integer.t

  defmacro __using__(_params) do
    quote do
      @behaviour ZXUtil.IdHasher

      def hashid(id) when is_integer(id), do: ZXUtil.IdHasher.hashid(id)
      def hashid(%{:id => id}), do: hashid(id)
      def hashid(_), do: nil
      def id_for_hash(hashed_id), do: ZXUtil.IdHasher.dehashid(hashed_id)

    end
  end
end
