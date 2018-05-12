defmodule IPC.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      IPC.Server,
      IPC.Storage,
      supervisor(IPC.ClientSupervisor, [], name: IPC.ClientSupervisor)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
