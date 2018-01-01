
defmodule Moola.Account do
  @moduledoc """
  The Account context.
  """

  use Moola, :context
  alias Moola.Auth
  alias Moola.UserToken
  alias Moola.Email
  alias Moola.Phone

  @default_password "asdf"

  ## Naming convention: get_* methods that don't end in ! return nil if no result. Ones that end in ! raise error if not found

  @doc """
  Register new user via email
  """
  def register(%{"email" => email} = params) do
    with {:ok, %User{} = user} <- params |> Map.put("password", @default_password) |> create_user,
    {:ok, %UserToken{} = user_token} <- Auth.create_user_token(user) do
      {:ok, user, user_token}
    else 
      _ -> {:error, "error registering new user"}
    end
  end

  def register(_), do: {:error, "error registering new user"}

  @doc """
  Login via email + password
  """
  def login(%{"id" => id, "password" => password}) do
    with %User{} = user <- lookup_user(id),
      {:ok, _} <- Auth.validate_password(user, password),
      {:ok, %UserToken{} = user_token} <- Auth.create_user_token(user) do
        {:ok, user, user_token}      
    else
      _ -> {:error, "unable to log in"}
    end
  end

  def login(_), do: {:error, "unable to log in"}

  def create_user(%{"email" => email} = attrs) do

    user_params = attrs 
    |> Map.take(["password", "status", "level", "nickname", "registration_ip"]) 
    |> Map.put_new("status", "pending")
    |> Map.put_new("level", "noob")
    
    email_params = %{"email" => email}

    with {:ok, user} = result <- %User{} |> User.changeset(user_params) |> Repo.insert,
      {:ok, email} <- create_email(user, email_params) 
    do
      result
    else
      err -> err
    end
  end

  def create_user(attrs \\ %{}) do
    {:error, "unable to create new user"}
  end

  def update_user(%User{} = user, attrs) do
    user 
    |> User.changeset(attrs)
    |> Repo.update
    |> push_user_updates
  end

  def push_user_updates(entity) do
    with %User{} = user <- entity |> as(User), do: send_channel(user, "update", %{users: [user]})
    entity
  end

  # Lookup functions:

  def get_email_by_address(address) do
    address = Email.normalize(address)
    case Repo.one(from e in Email, where: e.email == ^address, preload: [:user]) do
      %Email{} = email -> email
      _ -> nil
    end
  end

  def get_user_by_email(address) do
    case get_email_by_address(address) do
      %Email{} = email -> email.user
      _ -> nil
    end
  end

  def get_phone_by_number(number) do
    number = Phone.normalize(number)
    case Repo.one(from p in Phone, where: p.number == ^number, preload: [:user]) do
      %Phone{} = phone -> phone
      _ -> nil
    end
  end

  def get_user_by_phone(number) do
    case get_phone_by_number(number) do
      %Phone{} = phone -> phone.user
      _ -> nil
    end
  end

  def get_user_by_username(username) do
    username = String.downcase(username)
    Repo.one(from p in User, where: p.nickname == ^username)
  end

  def lookup_user(needle) do
    get_user_by_email(needle) || get_user_by_phone(needle) || get_user_by_username(needle) || nil
  end

  @doc """
  Adds a phone record for a user. If successful, deletes previous phone records.
  """
  def create_phone(%User{} = user, %{"number" => number} = attrs) do

    case Ecto.build_assoc(user, :phones)
    |> Phone.changeset(attrs)
    |> Repo.insert do
      {:ok, phone} = result ->
        # Send verification code:
        if !phone.verified_at do
          message_body = "Moolamates code: " <> phone.code
          Moola.Twilio.send_message(phone, message_body)
        end

        # Delete other phone records:
        user 
        |> User.load_emails_and_phones 
        |> Map.get(:phones)
        |> Enum.filter(fn(ph) -> ph.number != Phone.normalize(number) end)
        |> Enum.each(&Repo.delete/1)

        result
      err -> err 
    end
  end

  @doc """
  Verify phone using the numeric code that was sent to it.
  """  
  def verify_phone(%User{} = user, code) do
    user 
    |> User.get_assoc(:phones) 
    |> Enum.reduce({:error, "unable to verify"}, fn(phone, acc) -> 
      case verify_phone(phone, code) do
        {:ok, _} = success -> success
        err -> acc
      end
    end)
  end

  def verify_phone(%Phone{} = phone, code) do
    case phone.code do 
      ^code ->
        case phone.verified_at do
          nil ->
            phone
            |> Phone.changeset(%{"verified_at" => DateTime.utc_now})
            |> Repo.update
          _ ->
            {:ok, phone}
        end
      _ -> {:error, "incorrect code"}
    end
  end

  def get_email(address), do: Repo.get_by(Email, email: Email.normalize(address))

  @doc """
  Creates an email associated with user
  """
  def create_email(%User{} = user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:emails) 
    |> Email.changeset(attrs) 
    |> Repo.insert
  end

  def update_email(%Email{} = email, attrs) do
    email
    |> Email.changeset(attrs) 
    |> Repo.update
  end

  @doc """
  Adds a phone record for a user. If successful, deletes previous phone records.
  """
  def create_email(%User{} = user, %{"email" => address} = attrs) do

    case user 
    |> Ecto.build_assoc(:emails)
    |> Email.changeset(attrs)
    |> Repo.insert do
      {:ok, email} = result ->
        # Send confirmation email: 
        if !email.verified_at do
          # XXX
        end

        # Delete other emails:
        user 
        |> User.load_emails_and_phones 
        |> Map.get(:emails)
        |> Enum.filter(fn(em) -> em.email != Email.normalize(address) end)
        |> Enum.each(&Repo.delete/1)

        result
      err -> err
    end
  end

  @doc """
  Verifies an email.
  """
  def verify_email(%Email{} = email, code) do
    case email.code do 
      ^code ->
        case email.verified_at do
          nil ->
            email
            |> Email.changeset(%{"verified_at" => DateTime.utc_now})
            |> Repo.update
          _ ->
            {:ok, email}
        end
      _ -> {:error, "incorrect code"}
    end
  end

  def verify_email(%User{} = user, code) do
    user 
    |> User.get_assoc(:emails) 
    |> Enum.reduce({:error, "unable to verify"}, fn(email, acc) -> 
      case verify_phone(email, code) do
        {:ok, _} = success -> success
        err -> acc
      end
    end)
  end

end