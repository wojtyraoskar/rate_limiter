defmodule RLWeb.Plugs.UserMinuteLimiterPlug do
  import Plug.Conn
  @behaviour Plug

  # … per 60 seconds
  @window_ms 60_000

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    case Map.get(conn.params, "name") do
      nil ->
        conn
        |> put_resp_header("retry-after", "60")
        |> send_resp(401, "User ID Required")
        |> halt()

      id ->
        case RL.Storage.allow({:user, id}, @window_ms) do
          :ok ->
            conn

          {:error, _} ->
            conn
            |> put_resp_header("retry-after", "60")
            |> send_resp(429, "Too Many Requests")
            |> halt()
        end
    end
  end
end

defmodule RLWeb.Plugs.RateLimiterPlug do
  import Plug.Conn
  @behaviour Plug

  @window_ms 60_000

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    case RL.Storage.allow(conn.cookies["_rate_limiter_key"], @window_ms) do
      :ok ->
        conn

      {:error, _} ->
        conn
        |> put_resp_header("retry-after", "60")
        |> send_resp(429, "Too Many Requests")
        |> halt()
    end
  end
end
