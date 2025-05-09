# Distributed Rate Limiter with Horde

A distributed rate limiting system built with Elixir, Phoenix, and Horde that enforces both time-based and request count limits across multiple nodes.

## Key Features

- Distributed rate limiting using Horde for process management
- CRDT-based state synchronization across nodes
- Rate limiting with both time windows and request counts
- Automatic process recovery
- HTTP API endpoints for rate limit checking

## Rate Limiting Rules

- **Per User**: 5 requests per 60 seconds
- **Per Browser**: 5 requests per 60 seconds
- Limits are enforced across all nodes in the cluster

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

Start multiple nodes to demonstrate distributed rate limiting:

1. Start the first node:
```bash
iex --sname node1 --cookie wojtyra -S mix phx.server
```

2. Start the second node:
```bash
PORT=4001 iex --sname node2 --cookie wojtyra -S mix phx.server
```

The nodes will automatically connect and synchronize their state.

## Usage Examples

### Rate Limiting Per User

The system provides rate limiting per user through the query param "name":

```bash
# First 5 requests within 60 seconds - should succeed
curl -X GET "http://localhost:4000/user_home?name=John"
curl -X GET "http://localhost:4000/user_home?name=John"
curl -X GET "http://localhost:4000/user_home?name=John"
curl -X GET "http://localhost:4000/user_home?name=John"
curl -X GET "http://localhost:4000/user_home?name=John"

# 6th request within 60 seconds - should be blocked
curl -X GET "http://localhost:4000/user_home?name=John"
```

### Rate Limiting Per Browser

The system also provides rate limiting per browser using cookies:

```bash
# First 5 requests within 60 seconds - should succeed
curl -X GET "http://localhost:4000"

# 6th request within 60 seconds - should be blocked
curl -X GET "http://localhost:4000"
```

### Distributed Rate Limiting

The rate limiting state is synchronized across nodes. You can test this by making requests to different nodes:

```bash
# Make 3 requests to first node
curl -X GET "http://localhost:4000/user_home?name=John"
curl -X GET "http://localhost:4000/user_home?name=John"
curl -X GET "http://localhost:4000/user_home?name=John"

# Make 2 requests to second node (same user) - should succeed
curl -X GET "http://localhost:4000/user_home?name=John"
curl -X GET "http://localhost:4000/user_home?name=John"

# 6th request to either node - should be blocked
curl -X GET "http://localhost:4000/user_home?name=John"
```

## How It Works

1. **Process Management**: Horde manages the distributed processes across nodes
2. **State Synchronization**: DeltaCrdt ensures state is synchronized across nodes
3. **Rate Limiting**: The system tracks both request timestamps and counts, enforcing limits of 5 requests per 60 seconds
4. **Recovery**: If a process dies, Horde automatically starts a new one and DeltaCrdt synchronizes the state

## Programmatic Usage

You can also use the rate limiter programmatically in your Elixir code using `RL.Storage.allow/3`:

```elixir
# Check if a request is allowed (returns :ok or {:error, :rate_limited})
RL.Storage.allow("user", 60_000, 5)  # 5 requests per 60 seconds

# With default values (5 requests per 10 seconds)
RL.Storage.allow("user")

# Custom window and limit
RL.Storage.allow("user", 30_000, 10)  # 10 requests per 30 seconds
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License
