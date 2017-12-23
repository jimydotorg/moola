defmodule Moola.User do
  use Moola, :schema
  alias Moola.User
  alias Moola.Repo

  schema "users" do

    field :nickname, :string
    field :deleted_nickname, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :registration_ip, :string
    field :level, :integer

    has_many :user_tokens, Moola.UserToken

    has_many :emails, Moola.Email
    has_many :phones, Moola.Phone
    
    field :deleted_at, :utc_datetime
    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:password, :level, :nickname, :deleted_nickname, :status, :registration_ip])
    |> hash_password
  end

  defp hash_password(changeset) do
    case get_change(changeset, :password) do
      nil -> changeset
      new_pass -> changeset |> put_change(:password_hash, Comeonin.Bcrypt.hashpwsalt(new_pass))
    end
  end

  def load_emails_and_phones(%User{} = user) do
    user 
    |> Repo.preload(:emails)
    |> Repo.preload(:phones)
  end

  def get_emails(%User{} = user), do: user |> load_emails_and_phones |> Map.get(:emails)
  def get_phones(%User{} = user), do: user |> load_emails_and_phones |> Map.get(:phones)  

end

defimpl Poison.Encoder, for: Moola.User do
  use Moola, :encoder
  
  def encode(%User{} = user, options \\ []) do
    options = case options[:is_me] do
      nil -> [ {:is_me, options[:current_user] == user} | options]
      _ -> options
    end

    result = for_all(user, options)

    result = if options[:is_me] do
      Map.merge(result, for_self(user, options))
    else
      result
    end

    Poison.Encoder.encode(result, options)
  end

  def for_all(%User{} = user, options) do
    %{
      id: User.hashid(user)
    }
  end

  def for_self(%User{} = user, options) do
    %{
    }
  end

end