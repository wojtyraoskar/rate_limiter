defmodule RL.Application do
  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies)

    children = [
      RLWeb.Telemetry,
      RL.Repo,
      RLWeb.Endpoint,
      {Cluster.Supervisor, [topologies, [name: RL.ClusterSupervisor]]},
      {Horde.Registry, keys: :unique, name: RL.Registry},
      {RL.StorageSupervisor, [[], [name: RL.StorageSupervisor]]},
      %{
        id: :rate_limiter_horde_connector,
        restart: :transient,
        start: {
          Task,
          :start_link,
          [
            fn ->
              # Join nodes to distributed Registry
              Horde.Cluster.set_members(RL.Registry, membership(RL.Registry, nodes()))

              # Establish RL lot CRDT network
              RL.StorageSupervisor.join_neighbourhood(nodes())
            end
          ]
        }
      }
    ]

    opts = [strategy: :one_for_one, name: RL.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    RLWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp nodes do
    [Node.self()] ++ Node.list()
  end

  defp membership(horde, nodes) do
    Enum.map(nodes, fn node -> {horde, node} end)
  end
end
