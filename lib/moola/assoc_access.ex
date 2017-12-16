defmodule Moola.AssocAccess do

  defmacro __using__(_params) do
    quote do
      def load_assoc(%{} = item, assoc), do: item |> Moola.Repo.preload(assoc)
      def get_assoc(%{} = item, assoc), do: item |> load_assoc(assoc) |> Map.get(assoc)
    end
  end

end
