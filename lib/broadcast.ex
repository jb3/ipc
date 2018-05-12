defmodule IPC.Broadcast do
  def broadcast(clients, from, channel, message) do
    clients = clients |> Map.to_list() |> Enum.map(fn x -> elem(x, 1) end)

    subscribed_clients = Enum.filter(clients, fn x -> is_subscribed(x, channel) end)

    payload =
      %{
        from: from,
        channel: channel,
        message: message
      }
      |> IPC.Encoder.encode()
    

    Enum.each(subscribed_clients, fn client ->
      if client[:id] != from do
        :gen_tcp.send(client[:port], payload)
      end
    end)
  end

  defp is_subscribed(client, channel) do
    Enum.find(Tuple.to_list(client[:subscribed]), fn chan -> chan == channel end) != nil
  end
end
