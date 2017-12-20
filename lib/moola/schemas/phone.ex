defmodule Moola.Phone do
  use Moola, :schema
  alias Moola.Phone
  alias Moola.User

  schema "phones" do
    field :code, :string
    field :number, :string
    field :last_notified_at, :utc_datetime
    field :verified_at, :utc_datetime

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(%Phone{} = phone, attrs) do

    code = phone.code || ZXUtil.RandomString.generate(4, :numeric)
    attrs = attrs |> Map.put_new("code", code)

    phone
    |> cast(attrs, [:number, :code, :verified_at, :last_notified_at])
    |> validate_required([:number, :code])
    |> update_change(:number, &normalize/1)
    |> validate_format(:number, ~r/^[0-9]{10,15}$/)
    |> unique_constraint(:number)
  end

  def normalize(number) do
    ZXUtil.filter_non_numeric(number)
  end

end

defimpl Poison.Encoder, for: Moola.Phone do
  alias Moola.Phone

  def encode(%Phone{} = phone, options) do
    %{
      number: phone.number,
    }
    |> put_verified_if_me(phone, options[:is_me])
    |> Poison.Encoder.encode(options)
  end

  def put_verified_if_me(%{} = map, %Phone{} = phone, nil), do: map

  def put_verified_if_me(%{} = map, %Phone{} = phone, _) do
    map |> Map.put(:verified, phone.verified_at != nil)
  end

end