defmodule Master do
  use GenServer

  def start(main, nodesNum, topology, algorithm) do
    App.start("", "")

    state = %{
      :main => main,
      :nodesNum => nodesNum,
      :topology => topology,
      :algorithm => algorithm,
      :conv => 0,
      :reach => 0,
      :died => 0,
      :convrate => 0.9
    }

    GenServer.start_link(__MODULE__, state, name: via_tuple("master"))
  end

  def init(state) do
    nodesNum = state[:nodesNum]
    topology = state[:topology]
    algorithm = state[:algorithm]

    case algorithm do
      "gossip" ->
        case topology do
          "full" ->
            Topology.create_topology(topology, nodesNum, algorithm)
            GenServer.cast(via_tuple(Enum.random(0..(nodesNum - 1))), {:rumor, "Message"})

          "line" ->
            Topology.create_topology(topology, nodesNum, algorithm)
            GenServer.cast(via_tuple(Enum.random(0..(nodesNum - 1))), {:rumor, "Message"})

          "3Dtorus" ->
            num = round(:math.pow(nodesNum, 1 / 3))
            GenServer.cast(self(), {:set_nodes, num * num * num})
            Topology.create_topology(topology, nodesNum, algorithm)

            GenServer.cast(
              via_tuple([
                Enum.random(0..(num - 1)),
                Enum.random(0..(num - 1)),
                Enum.random(0..(num - 1))
              ]),
              {:rumor, "Message"}
            )

          "rand2D" ->
            Topology.create_topology(topology, nodesNum, algorithm)
            GenServer.cast(via_tuple(Enum.random(0..(nodesNum - 1))), {:rumor, "Message"})

          _ ->
            IO.puts("Invaid topology!")
        end

      "push-sum" ->
        case topology do
          "full" ->
            Topology.create_topology(topology, nodesNum, algorithm)
            GenServer.cast(via_tuple(Enum.random(0..(nodesNum - 1))), {:get_sum, 0, 0})

          "line" ->
            Topology.create_topology(topology, nodesNum, algorithm)
            GenServer.cast(via_tuple(Enum.random(0..(nodesNum - 1))), {:get_sum, 0, 0})

          "3Dtorus" ->
            num = round(:math.pow(nodesNum, 1 / 3))
            GenServer.cast(self(), {:set_nodes, num * num * num})
            Topology.create_topology(topology, nodesNum, algorithm)

            GenServer.cast(
              via_tuple([
                Enum.random(0..(num - 1)),
                Enum.random(0..(num - 1)),
                Enum.random(0..(num - 1))
              ]),
              {:get_sum, 0, 0}
            )

          "rand2D" ->
            Topology.create_topology(topology, nodesNum, algorithm)
            GenServer.cast(via_tuple(Enum.random(0..(nodesNum - 1))), {:get_sum, 0, 0})

          _ ->
            IO.puts("Invaid topology!")
        end

      _ ->
        IO.puts("Invaid algorithm")
    end

    state = Map.put(state, :starttime, :os.system_time(:millisecond))
    {:ok, state}
  end

  def handle_cast({:converged, _}, state) do
    endTime = :os.system_time(:millisecond)
    state = Map.put(state, :conv, state[:conv] + 1)
    state = Map.put(state, :died, state[:died] + 1)

    if(state[:died] / state[:nodesNum] >= state[:convrate]) do
      s =
        "#{state[:conv] * 100 / state[:nodesNum]} % converged in #{endTime - state[:starttime]} ms"

      send(state[:main], s)
      die(state, endTime)
    end

    {:noreply, state}
  end

  def handle_cast({:got_rumor, _}, state) do
    state = Map.put(state, :reach, state[:reach] + 1)
    {:noreply, state}
  end

  def handle_cast({:dying, _}, state) do
    state = Map.put(state, :died, state[:died] + 1)
    {:noreply, state}
  end

  def handle_cast({:set_nodes, num}, state) do
    state = Map.put(state, :nodesNum, num)
    {:noreply, state}
  end

  def handle_cast({:print, text}, state) do
    print(text)
    {:noreply, state}
  end

  def print(text) do
    IO.puts(text)
  end

  def die() do
    Process.exit(self(), :normal)
  end

  def die(state, endTime) do
    IO.puts(
      " #{state[:conv] * 100 / state[:nodesNum]} % converged in #{endTime - state[:starttime]} ms"
    )

    Process.exit(self(), :normal)
  end

  def getconv() do
    state = GenServer.call(via_tuple("master"), :get_conv)
    endTime = :os.system_time(:millisecond)

    IO.puts(
      "##{state[:conv] * 100 / state[:nodesNum]} % converged in #{endTime - state[:starttime]} ms"
    )
  end

  def handle_call(:get_conv, _, state) do
    {:reply, state, state}
  end

  def via_tuple(id) do
    {:via, Registry, {:process_registry, id}}
  end
end
