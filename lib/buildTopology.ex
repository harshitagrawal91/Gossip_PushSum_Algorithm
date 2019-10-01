defmodule Topology do
  def create_topology(topology_name, nodesNum, algorithm) do
    case topology_name do
      "full" ->
        for n <- 0..(nodesNum - 1) do
          if(algorithm == "gossip") do
            weight_state = %{
              :master => Master.via_tuple("master"),
              :id => n,
              :state => "initial",
              :count => 0,
              :msg => "",
              :neighbors => Enum.reject(0..(nodesNum - 1), fn nodes -> nodes == n end)
            }

            Nodes.start(n, weight_state)
          else
            weight_state = %{
              :master => Master.via_tuple("master"),
              :id => n,
              :state => "initial",
              :count => 0,
              :sum => n,
              :weight => 1,
              :neighbors => Enum.reject(0..(nodesNum - 1), fn nodes -> nodes == n end)
            }

            Nodes.start(n, weight_state)
          end
        end

      "line" ->
        for n <- 0..(nodesNum - 1) do
          if(algorithm == "gossip") do
            weight_state = %{
              :master => Master.via_tuple("master"),
              :id => n,
              :state => "initial",
              :count => 0,
              :msg => "",
              :neighbors => Enum.reject([n - 1, n + 1], fn nodes -> nodes == -1 || nodes == nodesNum end)
            }

            Nodes.start(n, weight_state)
          else
            weight_state = %{
              :master => Master.via_tuple("master"),
              :id => n,
              :state => "initial",
              :count => 0,
              :sum => n,
              :weight => 1,
              :neighbors => Enum.reject([n - 1, n + 1], fn nodes -> nodes == -1 || nodes == nodesNum end)
            }

            Nodes.start(n, weight_state)
          end
        end

      "3Dtorus" ->
        num = round(:math.pow(nodesNum, 1 / 3))
        GenServer.cast(self(), {:set_nodes, num * num * num})

        for i <- 0..(num - 1) do
          for j <- 0..(num - 1) do
            for k <- 0..(num - 1) do
              neighbors =
                Enum.reject(
                  [
                    [i - 1, j, k],
                    [i + 1, j, k],
                    [i, j - 1, k],
                    [i, j + 1, k],
                    [i, j, k - 1],
                    [i, j, k + 1]
                  ],
                  fn [x, y, z] ->
                    x == -1 || y == -1 || z == -1 || x == num || y == num || z == num
                  end
                )

              if(algorithm == "gossip") do
                weight_state = %{
                  :master => Master.via_tuple("master"),
                  :id => [i, j, k],
                  :state => "initial",
                  :count => 0,
                  :msg => "",
                  :neighbors => neighbors
                }

                Nodes.start([i, j, k], weight_state)
              else
                weight_state = %{
                  :master => Master.via_tuple("master"),
                  :id => [i, j, k],
                  :state => "initial",
                  :count => 0,
                  :sum => i * num * num + j * num + k,
                  :weight => 1,
                  :neighbors => neighbors
                }

                Nodes.start([i, j, k], weight_state)
              end
            end
          end
        end

      "rand2D" ->
        nodes = Enum.map(0..(nodesNum - 1), fn n -> [n, :rand.uniform(), :rand.uniform()] end)

        Enum.each(nodes, fn [n1, x1, y1] ->
          neighbors =
            Enum.map(
              Enum.filter(nodes, fn [n2, x2, y2] ->
                (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1) < 0.01 and n2 != n1
                IO.puts("waiting to converge...")
              end),
              fn [n, _, _] -> n end
            )

          if(algorithm == "gossip") do
            weight_state = %{
              :master => Master.via_tuple("master"),
              :id => n1,
              :state => "initial",
              :count => 0,
              :msg => "",
              :neighbors => neighbors
            }

            Nodes.start(n1, weight_state)
          else
            weight_state = %{
              :master => Master.via_tuple("master"),
              :id => n1,
              :state => "initial",
              :count => 0,
              :sum => n1,
              :weight => 1,
              :neighbors => neighbors
            }

            Nodes.start(n1, weight_state)
          end
        end)

      _ ->
        IO.puts("Invaid topology!")
    end
  end
end
