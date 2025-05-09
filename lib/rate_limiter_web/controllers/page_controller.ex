defmodule RLWeb.PageController do
  use RLWeb, :controller

  def home(conn, _params) do
    render(conn, :home, layout: false)
  end

  def user_home(conn, %{"name" => name}) do
    render(conn, :user_home, layout: false, name: name)
  end
end
