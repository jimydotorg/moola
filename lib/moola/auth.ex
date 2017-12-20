defmodule Moola.Auth do
  @moduledoc """
  The Auth context.
  """
  use Moola, :context

  alias Moola.ClientToken
  alias Moola.UserToken
  alias Moola.User
  
  @doc """
  Validates given token string.
  """
  def get_client_token(token_string) do
    Repo.get_by(ClientToken, token: token_string)
  end

  @doc """
  Creates a client_token.
  """
  def create_client_token(attrs \\ %{}) do
    %ClientToken{}
    |> ClientToken.create_changeset(attrs)
    |> Repo.insert
  end

  @doc """
  Updates a client_token.
  """
  def update_client_token(%ClientToken{} = client_token, attrs) do
    client_token
    |> ClientToken.update_changeset(attrs)
    |> Repo.update
  end

  def delete_client_token(%ClientToken{} = client_token), do: Repo.delete(client_token)

  # User tokens

  @doc """
  Gets a single user_token. user is preloaded.
  """
  def get_user_token!(token_string) do
    user_token = Repo.get_by!(UserToken, token: token_string) |> Repo.preload(:user)
  end

  def get_user_token(token_string) do
    try do
      get_user_token!(token_string)
    rescue
      Ecto.NoResultsError -> nil
    end
  end

  @doc """
  Creates a user_token. Token value is automatically generated if not specified
  """
  def create_user_token(%User{} = user, attrs \\ %{}) do
    Ecto.build_assoc(user, :user_tokens)
    |> UserToken.create_changeset(attrs)
    |> Repo.insert()
  end

  def delete_user_token(%UserToken{} = user_token), do: Repo.delete(user_token)

  def validate_password(%User{} = user, password) when bit_size(password) > 0 do
    try do
      Comeonin.Bcrypt.check_pass(user, password)
    rescue
      _ -> nil
    end
  end

end
