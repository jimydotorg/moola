defmodule Moola.NotifyChannels do

  import Plug.Conn
  import Phoenix.Socket

  alias Moola.User

  @doc """
  Sends messages to targeted channels. Output = input for easy inlining
  """
  def send_channel(target, event, data, encode_options \\ [])

  def send_channel(channel_list, event, data, options) when is_list(channel_list) do
    channel_list |> Enum.map(fn(channel) -> send_channel(channel, event, data, options) end)
  end

  def send_channel(%User{} = user, event, data, options) do
    options = options ++ [current_user: user]
    send_channel("user:" <> User.hashid(user), event, data, options)
    user
  end

  def send_channel(channel, event, %{} = data, options) when is_bitstring(channel) do
    output = data
    |> Map.put(:api, MoolaWeb.Endpoint.api_version)
    |> Poison.encode!(options)
    |> Poison.decode!

    MoolaWeb.Endpoint.broadcast(channel, event, output)
    channel
  end

  def send_channel(nil, _, _, _), do: nil

  def send_channel(wtf, _, _, _) do
    wtf |> ZX.i("unknown channel")
    nil
  end

end