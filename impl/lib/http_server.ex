defmodule Gaia20.HTTPServer do
  def init(_type, req, _opts) do
    {:ok, req, :nostate}
  end

  defp handle_lookup(request, host, state) do
    {:ok, reply} = case Gaia20.Data.get(host) do
      :nx ->
        :cowboy_req.reply(
          404,
          [{"content-type", "text/plain"}],
          "#{host} is unknown",
          request
        )

      {:redirect, redirect} ->
        corrected_redirect = case String.starts_with?(redirect, "http") do
          true -> redirect
          false -> "http://" <> redirect
        end
        :cowboy_req.reply(
          301,
          [{"location", corrected_redirect}],
          "",
          request
        )
    end

    {:ok, reply, state}
  end

  defp handle_meta_http(request, state) do
    {:ok, reply} = :cowboy_req.reply(
      404,
      [{"content-type", "text/html"}],
      Gaia20.Data.all() |> Enum.sort() |> Gaia20.Data.to_html(),
      request
    )


    {:ok, reply, state}
  end
  def handle(request, state) do
    {host, _} = :cowboy_req.host(request)

    case host do
      "gaia20.com" -> handle_meta_http(request, state)
      "localhost" -> handle_meta_http(request, state)
      _ -> handle_lookup(request, host, state)
    end
  end

  def terminate(_reason, _request, _state), do: :ok

  def start_link(port) do
    dispatch_config = :cowboy_router.compile([
      {:_,
       [
         {:_, __MODULE__, []}
       ]}
    ])

    :cowboy.start_http(:http, 10, [{:port, port}], [{:env, [{:dispatch, dispatch_config}]}])
  end
end
