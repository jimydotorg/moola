defmodule Moola.AssocAccess do

  defmacro __using__(_params) do
    quote do
      def load_assoc(%{} = item, assoc), do: item |> Moola.Repo.preload(assoc)
      def get_assoc(%{} = item, assoc, default \\ nil), do: item |> load_assoc(assoc) |> Map.get(assoc, default)
    end
  end

end

defmodule Moola do
  @moduledoc """
  Moola keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def schema do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
      alias Moola.Repo

      use Moola.AssocAccess
      use ZXUtil.IdHasher
      import Moola.Util
    end
  end

  def context do
    quote do
      import Ecto.Query, warn: false
      alias Ecto.Changeset
      alias Moola.Repo

      import ZXUtil.IdHasher
      import Moola.Util
      import Moola.NotifyChannels

      alias Moola.User
      alias Moola.Log
    end
  end

  def encoder do
    quote do
      import ZXUtil.IdHasher
      import Moola.Util

      alias Moola.User
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

end