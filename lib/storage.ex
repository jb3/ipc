defmodule IPC.Storage do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> Map.new() end, name: __MODULE__)
  end

  def insert_client(port, id) do
    item = %{port: port, subscribed: {}, id: id}

    Agent.update(__MODULE__, fn state -> Map.put(state, id, item) end)
  end

  def remove_client(id) do
    Agent.update(__MODULE__, fn state ->
      Map.delete(state, id)
    end)
  end

  def edit_subscription(:add, channel, id) do
    Agent.update(__MODULE__, fn state ->
      orig = Map.get(state, id)
      subbed = orig[:subscribed] |> Tuple.append(channel)

      orig = Map.put(orig, :subscribed, subbed)

      Map.put(state, id, orig)
    end)
  end

  def edit_subscription(:remove, channel, id) do
    Agent.update(__MODULE__, fn state ->
      client = Map.get(state, id)

      client =
        Map.update!(
          client,
          :subscribed,
          &(&1 |> Tuple.to_list() |> List.delete(channel) |> List.to_tuple())
        )

      Map.put(state, id, client)
    end)
  end

  def get_client(id) do
    Agent.get(__MODULE__, fn state ->
      Map.get(state, id)
    end)
  end

  def get_all_clients do
    Agent.get(__MODULE__, fn state ->
      state
    end)
  end
end
