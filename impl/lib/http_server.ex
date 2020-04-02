defmodule Gaia20.HTTPServer do
  def init(_type, req, _opts) do
    {:ok, req, :nostate}
  end

  defp suffix_from_request(request) do
    target = cond do
      ({query_string, _} = :cowboy_req.qs(request)) != "" ->
        query_string
      true ->
        {host, _} = :cowboy_req.host(request)
        host
    end

    target
  end

  defp handle_lookup(request, host, state) do
    {:ok, reply} = case Gaia20.Data.get(host) do
      :nx ->
        {:ok, reply, _} = handle_meta_http(request, state, suffix_from_request(request))
        reply
        # :cowboy_req.reply(
        #   404,
        #   [{"content-type", "text/plain"}],
        #   "#{host} is unknown",
        #   request
        # )

      {:redirect, redirect, _aliasing} ->
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

  defp handle_meta_http(request, state, suffix) do
    {:ok, reply} = :cowboy_req.reply(
      200,
      [{"content-type", "text/html"}],
      Gaia20.Data.all_with_suffix(suffix) |> Enum.sort() |> Gaia20.Data.to_html(suffix),
      request
    )


    {:ok, reply, state}
  end
  def handle(request, state) do
    {host, _} = :cowboy_req.host(request)

    case host do
      "gaia20.com" -> handle_meta_http(request, state, suffix_from_request(request))
      "localhost" -> handle_meta_http(request, state, suffix_from_request(request))
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
