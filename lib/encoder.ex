defmodule IPC.Encoder do
  def encode(payload_map) do
    Poison.encode!(payload_map)
  end

  def decode(payload_string) do
    Poison.decode!(payload_string)
  end
end
