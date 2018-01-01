defmodule MoolaWeb.RenderJson do

  import Plug.Conn
  import Phoenix.Socket
  import Moola.Transmute

  alias Moola.User

  @ok_http_status 200
  @error_http_status 403

  @doc """
  Phoenix does not allow options to be passed into JSON encoder, so provide our own custom render json method.
  Options is passed into Poison encoder.
  Bonus: current_user is automatically added to options
  """

  # function head for render_error/4
  # https://elixirschool.com/en/lessons/basics/functions/#default-arguments
  def render_json(conn, data \\ %{}, options \\ [], status \\ :ok)

  def render_json(%Plug.Conn{} = conn, data, options, status) do

    options = case as(conn, User) do
      nil -> options
      %User{} = user -> options ++ [current_user: user]
      _ -> options
    end

    http_status = case status do
      :ok -> @ok_http_status
      :error -> @error_http_status
      _ -> 500
    end

    data = data |> Map.put(:api, MoolaWeb.Endpoint.api_version)

    conn 
    |> put_resp_header("content-type", "application/json; charset=utf-8")
    |> send_resp(http_status, Poison.encode!(data, options))
  end

  def render_json(%Phoenix.Socket{} = socket, data, options, status) do

    options = case as(socket, User) do
      nil -> options
      %User{} = user -> options ++ [current_user: user]
      _ -> options
    end

    output = data
    |> Map.put(:api, MoolaWeb.Endpoint.api_version)
    |> Poison.encode!(options)
    |> Poison.decode!

    {:reply, {status, output}, socket}
  end

  # function head for render_error/3 
  # https://elixirschool.com/en/lessons/basics/functions/#default-arguments
  def render_error(conn, payload \\ "error", options \\ [])

  def render_error(%Plug.Conn{} = conn, %{} = error, options) do
    render_json(conn, error, options, :error)
  end

  def render_error(%Phoenix.Socket{} = socket, %{} = data, options) do
    render_json(socket, data, options, :error)
  end

  def render_error(medium, {:error, %Ecto.Changeset{} = cs}, options) do
    # Todo: transform changeset errors into meaningful text
    cs |> IO.inspect
    err = "errorerrorerrorerror"
    render_error(medium, err, options)
  end

  def render_error(medium, {:error, message}, options) when is_bitstring(message) do
    render_error(medium, %{message: message}, options)
  end

  def render_error(medium, message, options) do
    render_error(medium, %{message: message}, options)
  end

  # Render nothing
  def render_nothing(%Phoenix.Socket{} = socket) do
    {:noreply, socket}
  end

  def render_nothing(%Plug.Conn{} = conn) do
    conn 
    |> send_resp(:ok, "")
  end

end
