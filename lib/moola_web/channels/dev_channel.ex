defmodule MoolaWeb.DevChannel do
  use MoolaWeb, :channel

  def join("dev:" <> id, params, socket) do
    {:ok, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("test", payload, socket) do
    socket
    |> render_json(%{hey: "you"})
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in(_, payload, socket) do
    {:reply, {:ok, payload}, socket} |> IO.inspect
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (toys:lobby).
  # def handle_in("shout", payload, socket) do
  #   broadcast(socket, "shout", payload)
  #   {:noreply, socket}
  # end

  # This is invoked every time a notification is being broadcast
  # to the client. The default implementation is just to push it
  # downstream but one could filter or change the event.
  # def handle_out(event, payload, socket) do
  #   push(socket, event, payload)
  #   {:noreply, socket}
  # end

end
