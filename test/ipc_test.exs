defmodule IPCTest do
  use ExUnit.Case
  doctest IPC

  test "connects to server" do
    socket = :gen_tcp.connect({0, 0, 0, 0}, 1122, [])

    assert {:ok, sock} = socket

    :gen_tcp.close(sock)
  end

  test "receives welcome payload" do
    {:ok, socket} = :gen_tcp.connect({0, 0, 0, 0}, 1122, [:list, packet: 0, active: false])
    {:ok, data} = :gen_tcp.recv(socket, 0)
    
    
    :gen_tcp.close(socket) # No more need for socket past here

    assert IPC.Encoder.decode(data)["op"] == "welcome"
  end

  test "can subscribe and unsubscribe" do
    {:ok, socket} = :gen_tcp.connect({0, 0, 0, 0}, 1122, [:list, packet: 0, active: false])
    {:ok, _welcome} = :gen_tcp.recv(socket, 0)

    payload = %{
      op: "subscribe",
      channel: "test"
    } |> IPC.Encoder.encode

    :gen_tcp.send(socket, payload)

    {:ok, data} = :gen_tcp.recv(socket, 0)

    assert IPC.Encoder.decode(data)["subscriptions"] == ["test"]

    payload = %{
      op: "leave",
      channel: "test"
    } |> IPC.Encoder.encode

    :gen_tcp.send(socket, payload)

    {:ok, data} = :gen_tcp.recv(socket, 0)

    assert IPC.Encoder.decode(data)["subscriptions"] == []

    :gen_tcp.close(socket)
  end

  test "messages can be broadcast and received" do
    {:ok, sock1} = :gen_tcp.connect({0, 0, 0, 0}, 1122, [:list, packet: 0, active: false])
    {:ok, sock2} = :gen_tcp.connect({0, 0, 0, 0}, 1122, [:list, packet: 0, active: false])
    
    {:ok, _welcome} = :gen_tcp.recv(sock1, 0)
    {:ok, _welcome} = :gen_tcp.recv(sock2, 0)

    payload = %{
      op: "subscribe",
      channel: "test"
    } |> IPC.Encoder.encode

    :gen_tcp.send(sock1, payload)

    {:ok, _data} = :gen_tcp.recv(sock1, 0)

    payload = %{
      op: "message",
      channel: "test",
      message: %{"hello" => "world"},
    } |> IPC.Encoder.encode

    :gen_tcp.send(sock2, payload)

    message = :gen_tcp.recv(sock1, 0) |> elem(1) |> IPC.Encoder.decode

    assert message["message"] == %{"hello" => "world"}
    assert message["channel"] == "test"

    :gen_tcp.close(sock1)
    :gen_tcp.close(sock2)
  end
end
