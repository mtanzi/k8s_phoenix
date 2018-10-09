defmodule K8sPhoenixWeb.HealthController do
  use K8sPhoenixWeb, :controller

  def health(conn, _params) do
    {:ok, hostname} = :inet.gethostname()

    response = %{
      ok: DateTime.utc_now() |> to_string,
      version: app_version(),
      hostname: to_string(hostname)
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(response))
  end

  defp app_version do
    {:ok, version} = :application.get_key(:k8s_phoenix, :vsn)
    version |> List.to_string()
  end
end
