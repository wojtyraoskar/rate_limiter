defmodule RL.StorageSupervisor do
  use Supervisor

  def start_link([args, opts]) do
    Supervisor.start_link(__MODULE__, args, opts)
  end

  def init(_args) do
    children = [
      # Manages distributed state
      {
        DeltaCrdt,
        on_diffs: fn _diffs -> send(RL.Storage, :update_state) end,
        sync_interval: 300,
        max_sync_size: :infinite,
        shutdown: 30_000,
        crdt: DeltaCrdt.AWLWWMap,
        name: RL.Storage.Crdt
      },
      # Interface for tracking state of cars through gates
      {RL.Storage, []}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  @doc """
  Wires up the CRDT.  Note that the spelling of 'neighbourhood'.  It's used
  everywhere, even in the docs, because that's how the function name is spelled
  in the CRDT library, which was apprently written by someone from the UK
  """
  def join_neighbourhood(nodes) do
    # Map all nodes to the CRDT process for that node
    crdts =
      Enum.map(nodes, fn node ->
        :rpc.call(node, Process, :whereis, [RL.Storage.Crdt])
      end)

    # Creates combinations of all possible node sets in the neighbourhood
    # i.e. for a set [1, 2, 3] -> [{1, [2, 3]}, {2, [1, 3]}, {3, [1, 2]}]
    combos = for crdt <- crdts, do: {crdt, List.delete(crdts, crdt)}

    # Enumerate the list wire up the neighbors
    Enum.each(combos, fn {crdt, crdts} ->
      :ok = DeltaCrdt.set_neighbours(crdt, crdts)
    end)
  end
end
