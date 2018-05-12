defmodule IPC.Server do
  use GenServer
  require Logger

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, listen_socket} =
      :gen_tcp.listen(1122, [:binary, ip: {0, 0, 0, 0}, active: false, reuseaddr: true])

    send(self(), {:loop, listen_socket})

    {:ok, listen_socket}
  end

  @impl true
  def handle_info({:loop, socket}, state) do
    {:ok, client} = :gen_tcp.accept(socket)
    id = UUID.uuid4()

    Logger.info("Received connection from client #{id}")
    Logger.debug("Port #{inspect(client)}")

    IPC.Storage.insert_client(client, id)

    {:ok, client_server_pid} = Supervisor.start_child(IPC.ClientSupervisor, [client, self(), id])

    Logger.debug("Spawned new child handler")

    :inet_tcp.controlling_process(client, client_server_pid)

    :inet.setopts(client, active: true)

    send(self(), {:loop, socket})

    {:noreply, state}
  end
end
