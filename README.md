# Distributed Rate Limiter with Horde

This is an example of a distributed rate limiting system built with Elixir, Phoenix, and Horde. The system demonstrates how to implement rate limiting across multiple nodes in a distributed system, with automatic process recovery and state synchronization.

## Key Features

- Distributed rate limiting using Horde for process management
- CRDT-based state synchronization across nodes
- Automatic process recovery
- Rate limiting per user and per browser
- HTTP API endpoints for rate limit checking
- Phoenix LiveView integration

## Architecture

The system uses:
- Horde for distributed process management
- DeltaCrdt for state synchronization
- Phoenix for the web interface
- GenServer for process state management

## Getting Started

### Prerequisites

- Elixir 1.14+
- Erlang/OTP 25+
- PostgreSQL

### Installation

1. Clone the repository
2. Install dependencies:
```bash
mix deps.get
```

3. Set up the database:
```bash
mix ecto.setup
```

### Running the System

Start two nodes to demonstrate distributed rate limiting:

1. Start the first node:
```bash
iex --sname oskar --cookie wojtyra -S mix phx.server
```

2. Start the second node:
```bash
PORT=4001 iex --sname oskar2 --cookie wojtyra -S mix phx.server
```

The nodes will automatically connect and synchronize their state.

## Usage Examples

### Rate Limiting Per User

The system provides rate limiting per user through the `X-User-Id` header:

```bash
# First request - should succeed
curl -X GET -H "X-User-Id: 1" http://localhost:4000/user_home?name=John

# Second request within rate limit window - should be blocked
curl -X GET -H "X-User-Id: 1" http://localhost:4000/user_home?name=John
```

### Rate Limiting Per Browser

The system also provides rate limiting per browser using cookies:

```bash
# First request - should succeed
curl -X GET http://localhost:4000/

# Second request within rate limit window - should be blocked
curl -X GET http://localhost:4000/
```

### Distributed Rate Limiting

The rate limiting state is synchronized across nodes. You can test this by making requests to different nodes:

```bash
# Request to first node
curl -X GET http://localhost:4000/user_home?name=John

# Request to second node (same user) - should be blocked
curl -X GET  http://localhost:4001/user_home?name=John
```

### Process Recovery

If a process dies, the system will automatically recover and maintain the rate limiting state:

1. Start both nodes
2. Make some requests to establish rate limiting state
3. Kill one of the nodes
4. Start a new node
5. The rate limiting state will be automatically synchronized

## Code Examples

### Using the Rate Limiter in Your Code

```elixir
# Check if a user is allowed
case RL.Storage.allow({:user, "user123"}, 60_000) do
  :ok -> 
    # User is allowed, proceed with the request
    {:ok, "Request processed"}
  
  {:error, :rate_limited} -> 
    # User is rate limited
    {:error, "Too many requests"}
end

# Check if a browser session is allowed
case RL.Storage.allow("browser_session_123", 10_000) do
  :ok -> 
    # Browser is allowed, proceed with the request
    {:ok, "Request processed"}
  
  {:error, :rate_limited} -> 
    # Browser is rate limited
    {:error, "Too many requests"}
end
```

### Adding Rate Limiting to Your Phoenix Routes

```elixir
# In your router.ex
pipeline :rate_limited do
  plug RLWeb.Plugs.UserMinuteLimiterPlug
end

scope "/", RLWeb do
  pipe_through [:browser, :rate_limited]
  
  get "/user_home", PageController, :user_home
end
```

## How It Works

1. **Process Management**: Horde manages the distributed processes across nodes
2. **State Synchronization**: DeltaCrdt ensures state is synchronized across nodes
3. **Rate Limiting**: The system tracks request timestamps and enforces rate limits
4. **Recovery**: If a process dies, Horde automatically starts a new one and DeltaCrdt synchronizes the state

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
