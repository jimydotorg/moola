# NOTES:

# Give Phoenix server node a name upon startup:
# elixir --sname SERVER_NODE_NAME -S mix phx.server

# then connect iex console to the Phoenix server:
# iex --sname SOME_NAME --remsh SERVER_NODE_NAME@hostname -S mix
# --OR--
# iex --sname SOME_NAME -S mix
# iex> Node.connect :SERVER_NODE_NAME@hostname

# then broadcast a message:
# iex> MoolaWeb.Endpoint.broadcast(CHANNEL_NAME, EVENT_NAME, %{your: "mom"})

defmodule MoolaWeb.MainSocket do
  use Phoenix.Socket
  alias Moola.ClientToken
  alias Moola.UserToken
  alias Moola.User
  alias Moola.Log

  ## Channels
  channel "ticker:*", MoolaWeb.TickerChannel
  channel "latency:*", MoolaWeb.LatencyChannel
  channel "dev:*", MoolaWeb.DevChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket
  # transport :longpoll, Phoenix.Transports.LongPoll

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.

  # Both client and user tokens presented
  def connect(%{"ct"=>client_token_string, "ut"=>user_token_string}, socket) do
    with %ClientToken{} = client_token <- Moola.Auth.get_client_token(client_token_string),
      %UserToken{} = user_token <- Moola.Auth.get_user_token(user_token_string)
    do 
      socket = socket 
      |> assign(:current_user, user_token.user) 
      |> assign(:client_token, client_token) 
      |> assign(:client_token_string, client_token.token) 
      |> Log.record("socket/connect")
      {:ok, socket}
    else
      _ -> :error
    end
  end

  # Only client token presented
  def connect(%{"ct"=>client_token_string}=params, socket) do
    with %ClientToken{} = client_token <- Moola.Auth.get_client_token(client_token_string) do
      socket = socket 
      |> assign(:client_token, client_token) 
      |> assign(:client_token_string, client_token.token) 
      |> Log.record("socket/connect")
      {:ok, socket}
    else
      _ -> :error
    end
  end

  # No client token passed, deny connection
  def connect(_params, socket) do
    socket |> Log.record("socket/connect_error")
    :error
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     MoolaWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(socket) do
    case socket.assigns[:current_user] do
      %User{} = user ->
        "user:#{User.hashid(user)}"
      _ ->
        case socket.assigns[:client_token_string] do
          nil -> nil
          _ -> "guest:" <> ZXUtil.md5(socket.assigns[:client_token_string])
        end
    end
  end

end
