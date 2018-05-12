defmodule IPC.ClientSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: IPC.ClientSupervisor)
  end

  def init(:ok) do
    spec = worker(IPC.ClientServer, [], restart: :temporary)

    options = [
      strategy: :simple_one_for_one,
      name: __MODULE__,
      restart: :temporary
    ]

    supervise([spec], options)
  end
end
