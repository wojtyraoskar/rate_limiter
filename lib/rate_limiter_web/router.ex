defmodule RLWeb.Router do
  use RLWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RLWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :user_rate_limiter do
    # ⬅ 1 user req / min
    plug RLWeb.Plugs.UserMinuteLimiterPlug
  end

  pipeline :request_rate_limiter do
    # ⬅ 1 browser req/ min
    plug RLWeb.Plugs.RateLimiterPlug
  end

  scope "/", RLWeb do
    pipe_through [:browser, :request_rate_limiter]

    get "/", PageController, :home
  end

  scope "/", RLWeb do
    pipe_through [:browser, :user_rate_limiter]

    get "/user", PageController, :user_home
    get "/user_home", PageController, :user_home
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:rate_limiter, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: RLWeb.Telemetry
    end
  end
end
