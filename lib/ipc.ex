defmodule IPC do
  use Application

  def start(_type, _args) do
    IPC.Supervisor.start_link(name: IPC.Supervisor)
  end
end
