defmodule RL.Storage do
  use GenServer

  require Logger

  @crdt RL.Storage.Crdt
  @default_window 10_000
  @default_limit 5

  # Client API

  def child_spec(config) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [config]}}
  end

  def start_link(config) do
    GenServer.start_link(__MODULE__, Map.new(config), name: __MODULE__)
  end

  def allow(key, window \\ @default_window, limit \\ @default_limit) do
    now = System.monotonic_time(:millisecond)

    case DeltaCrdt.get(@crdt, {:storage, key}) do
      nil ->
        # First request for this key
        DeltaCrdt.put(@crdt, {:storage, key}, {now, 1})
        :ok

      {last_time, _count} when now - last_time >= window ->
        # Window has expired, reset counter
        DeltaCrdt.put(@crdt, {:storage, key}, {now, 1})
        :ok

      {last_time, count} when count < limit ->
        # Within window and under limit, increment counter
        DeltaCrdt.put(@crdt, {:storage, key}, {last_time, count + 1})
        :ok

      _ ->
        # Either window hasn't expired or limit reached
        {:error, :rate_limited}
    end
  end

  @impl true
  def init(state) do
    Logger.debug("Storage initialized on node #{inspect(Node.self())}")
    {:ok, Map.put(state, :storage, %{})}
  end

  @impl true
  def handle_info(:update_state, state) do
    crdt_state = DeltaCrdt.to_map(RL.Storage.Crdt)

    storage =
      crdt_state
      |> Enum.group_by(fn {{k, _}, _} -> k end, fn {{_, kv}, v} -> {kv, v} end)
      |> Map.get(:storage, [])
      |> Map.new()

    {:noreply, %{state | storage: storage}}
  end
end
