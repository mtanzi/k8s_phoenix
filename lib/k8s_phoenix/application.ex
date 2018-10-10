defmodule K8sPhoenix.Application do
  use Application

  require Logger

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    topologies = [
      k8s: [
        strategy: Cluster.Strategy.Kubernetes,
        connect: {__MODULE__, :connect_node, []},
        disconnect: {__MODULE__, :disconnect_node, []},
        config: [
          mode: :ip,
          kubernetes_selector: "app=k8s-phoenix,env=production",
          kubernetes_node_basename: "k8s-phoenix",
          polling_interval: 5_000
        ]
      ]
    ]

    # Define workers and child supervisors to be supervised
    children = [
      {Cluster.Supervisor, [topologies, [name: SimpleApiWeb.ClusterSupervisor]]},
      # Start the endpoint when the application starts
      supervisor(K8sPhoenixWeb.Endpoint, [])
      # Start your own worker by calling: K8sPhoenix.Worker.start_link(arg1, arg2, arg3)
      # worker(K8sPhoenix.Worker, [arg1, arg2, arg3]),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: K8sPhoenix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def connect_node(node) do
    :net_kernel.connect_node(node)
    Logger.info("**** Connected #{inspect(node())} to #{inspect(node)}")
    true
  end

  def disconnect_node(node) do
    Logger.info("**** Disconnected #{inspect(node())} from #{inspect(node)}")
    true
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    K8sPhoenixWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
