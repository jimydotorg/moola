defmodule Moola.ClientToken do
  use Moola, :schema
  alias Moola.ClientToken


  schema "client_tokens" do
    field :collation, :string
    field :creating_ip, :string
    field :device_id, :string
    field :last_active_at, :utc_datetime
    field :token, :string

    timestamps()
  end

  @doc false
  def create_changeset(%ClientToken{} = client_token, attrs) do
    client_token
    |> cast(attrs, [:token, :device_id, :last_active_at, :creating_ip, :collation])
    |> put_change(:token, Ecto.UUID.generate())
    |> validate_required([:token, :creating_ip])
  end

  @doc """
  Only last_active_at may be updated after a client token has been created
  """
  def update_changeset(%ClientToken{} = client_token, attrs) do
    client_token
    |> cast(attrs, [:last_active_at])
    |> validate_required([:last_active_at])
  end

end

defimpl Poison.Encoder, for: Moola.ClientToken do
  alias Moola.ClientToken

  def encode(%ClientToken{} = client_token, options) do
    Poison.Encoder.encode(client_token.token, options)
  end

end
