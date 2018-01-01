defmodule Moola.Transmute do

  import Ecto.Query

  alias Moola.Auth
  alias Moola.User
  alias Moola.Phone
  alias Moola.Email

  @doc """
  Turn things into other things, even from id's, hashid's, and lists of id/hashes
  """

  # identity transforms:
  def as(%User{} = thing, User), do: thing

  def as(%Phone{} = phone, type), do: phone |> Phone.get_assoc(:user) |> as(type)
  def as(%Email{} = email, type), do: email |> Email.get_assoc(:user) |> as(type)

  # Working with Repo
  def as(%Ecto.Changeset{} = changes, type), do: changes |> Ecto.Changeset.apply_changes |> as(type)
  def as({:ok, entity}, type), do: entity |> as(type)

  # Request/channel authentication:
  def as(%Plug.Conn{} = conn, User), do: conn.assigns[:current_user]
  def as(%Phoenix.Socket{} = socket, User), do: socket.assigns[:current_user]
  def as(%{"ct" => client_token_string, "ut" => user_token_string}, User) do
    with %Moola.ClientToken{} <- Auth.get_client_token(client_token_string),
      %Moola.UserToken{} = user_token <- Auth.get_user_token(user_token_string) do 
      user_token.user
    else
      _ -> nil
    end
  end

  # LEAVE THIS AT THE BOTTOM OF THE FILE!
  def as(id, type) when is_integer(id), do: Moola.Repo.get(type, id)
  def as(hashid, type) when is_bitstring(hashid), do: hashid |> ZXUtil.IdHasher.dehashid |> as(type)
  def as([_|_] = list, type), do: list |> Enum.map(fn(x) -> as(x, type) end) 
  # ^^^ we do NOT try to optimize this by utilizing an "id in [id1, id2, ...]" query
  # because this would not preserve the order of the list.

  def as(nil, type), do: nil

  # DEBUG:
  def as(source, type) do
    source |> ZX.i("NIL transmutation!! from:")
    type |> ZX.i("to:")
    nil
  end

  def as(_, type), do: nil
end
