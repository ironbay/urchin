defmodule UrchinTest do
  use ExUnit.Case
  doctest Urchin

  test "greets the world" do
    assert Urchin.hello() == :world
  end
end
