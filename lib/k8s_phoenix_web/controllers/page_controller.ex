defmodule K8sPhoenixWeb.PageController do
  use K8sPhoenixWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
