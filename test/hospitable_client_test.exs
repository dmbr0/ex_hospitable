defmodule HospitableClientTest do
  use ExUnit.Case
  doctest HospitableClient

  test "greets the world" do
    assert HospitableClient.hello() == :world
  end
end
