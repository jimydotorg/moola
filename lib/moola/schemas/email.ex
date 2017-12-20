defmodule Moola.Email do
  use Moola, :schema
  alias Moola.Email
  alias Moola.User

  @mail_regex ~r/^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$/

  schema "emails" do
    field :code, :string
    field :email, :string
    field :last_notified_at, :utc_datetime
    field :verified_at, :utc_datetime

    belongs_to :user, User

    timestamps()
  end

  def changeset(%Email{} = email, attrs) do

    code = email.code || ZXUtil.RandomString.generate(6)
    attrs = attrs |> Map.put_new("code", code)

    email
    |> cast(attrs, [:email, :code, :verified_at, :last_notified_at])
    |> validate_required([:email])
    |> update_change(:email, &normalize/1)
    |> validate_format(:email, @mail_regex)
    |> unique_constraint(:email)
  end
  
  def normalize(address) do
    String.downcase(address)
  end

end

defimpl Poison.Encoder, for: Moola.Email do
  alias Moola.Email

  def encode(%Email{} = email, options) do
    %{
      address: email.email,
    }
    |> put_verified_if_me(email, options[:is_me])
    |> Poison.Encoder.encode(options)
  end

  def put_verified_if_me(%{} = map, %Email{} = email, nil), do: map

  def put_verified_if_me(%{} = map, %Email{} = email, _) do
    map |> Map.put(:verified, email.verified_at != nil)
  end

end