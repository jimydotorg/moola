defmodule Moola.UserToken do
  use Moola, :schema
  alias Moola.User
  alias Moola.UserToken

  schema "user_tokens" do
    field :token, :string
    belongs_to :user, User
    timestamps()
  end

  @doc false
  def create_changeset(%UserToken{} = user_token, attrs) do
    user_token
    |> cast(attrs, [:token])
    |> add_token
    |> validate_required([:token, :user_id])
  end

  defp add_token(changeset) do
    case get_change(changeset, :token) do
      nil -> changeset |> put_change(:token, Ecto.UUID.generate())
      _ -> changeset
    end
  end

end

defimpl Poison.Encoder, for: Shop.Auth.UserToken do
  alias Moola.UserToken

  def encode(%UserToken{} = user_token, options) do
    Poison.Encoder.encode(user_token.token, options)
  end

end
