defmodule IPC.ClientServer do
  use GenServer
  require Logger

  def start_link(client, server, id) do
    Logger.debug("Started child")
    GenServer.start(__MODULE__, [client, server, id])
  end

  def init([client, server, id]) do
    message = %{
      op: "welcome",
      id: id,
      subscriptions: [],
      message: "Hello, welcome."
    }

    message = IPC.Encoder.encode(message)

    :gen_tcp.send(client, message)

    {:ok, %{server: server, client: client, id: id}}
  end

  def handle_info({:tcp, _port, message}, state) do
    Logger.debug("Received message from #{Map.get(state, :id)}: #{message |> String.trim}")

    payload = IPC.Encoder.decode(message)

    case Map.get(payload, "op") do
      "subscribe" ->
        IPC.Storage.edit_subscription(:add, Map.get(payload, "channel"), state[:id])

        message = %{
          op: "confirmation",
          id: state[:id],
          channel: Map.get(payload, "channel"),
          subscriptions: IPC.Storage.get_client(state[:id])[:subscribed] |> Tuple.to_list,
          message: "Subscribed to channel"
        }

        to_send = IPC.Encoder.encode(message)
        :gen_tcp.send(state[:client], to_send)
        {:noreply, state}
      "leave" ->
        IPC.Storage.edit_subscription(:remove, Map.get(payload, "channel"), state[:id])
        
        message = %{
          op: "confirmation",
          id: state[:id],
          channel: Map.get(payload, "channel"),
          subscriptions: IPC.Storage.get_client(state[:id])[:subscribed] |> Tuple.to_list,
          message: "Unsubscribed from channel"
        }

        to_send = IPC.Encoder.encode(message)
        :gen_tcp.send(state[:client], to_send)
        {:noreply, state}

      "message" ->
        Logger.debug("Incoming message into channel #{Map.get(payload, "channel")} from #{state[:id]}")

        IPC.Storage.get_all_clients()
        |> IPC.Broadcast.broadcast(
          state[:id],
          Map.get(payload, "channel"),
          Map.get(payload, "message")
        )

        {:noreply, state}
      _ ->
        message = %{
          op: "invalid_op",
          id: state[:id],
          message: "The opcode '#{Map.get(payload, "op")}' is invalid"
        }

        to_send = IPC.Encoder.encode(message)
        :gen_tcp.send(state[:client], to_send)
        IPC.Storage.remove_client(state[:id])
        Logger.info "Invalid op code from #{state[:id]}, client connection was terminated."
        {:stop, :normal, state}
    end
  end

  def handle_info({:tcp_closed, _port}, state) do
    Logger.info("Connection from #{Map.get(state, :id)} lost")
    IPC.Storage.remove_client(state[:id])
    {:stop, :normal, state}
  end
end
