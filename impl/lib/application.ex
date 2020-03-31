defmodule Gaia20.Application do
  use Application

  def start(_type, _args),
    do: Supervisor.start_link(children(), opts())

  defp children do
    [
      {Gaia20.DNSServer, 53},
      %{
        id: Gaia20.HTTPServer,
        start: {Gaia20.HTTPServer, :start_link, [80]}
      },
      %{
        id: Sentix,
        start: {Sentix, :start_link, [:data_yaml, ["data.yml"]]}
      },
      {Gaia20.Data, :ok},
    ]
  end

  defp opts do
    [
      strategy: :one_for_one,
      name: Gaia20.Supervisor
    ]
  end
end
