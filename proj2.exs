defmodule Gossip_pushSum do
  args = System.argv()

  if(Enum.count(args) == 3) do
    numNodes = String.to_integer(Enum.at(args, 0))
    topology = Enum.at(args, 1)
    algorithm = Enum.at(args, 2)
    Master.start(self(), numNodes, topology, algorithm) |> IO.inspect()
  else
    IO.puts("Invalid arguments!")
  end

  receive do
    result -> result
  end
end
