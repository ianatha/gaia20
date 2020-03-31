defmodule Gaia20.DNSServer do
  @moduledoc """
  Example implementing DNS.Server behaviour
  """
  @behaviour DNS.Server

  require Logger
  use DNS.Server

  def generate_soa(record) do
    {'gaia20.com', 'community.gaia20.com', 2018110201, 3600, 1800, 604800, 86400}
  end

  def generate_ns(record) do
    'dns1.gaia20.org'
  end

  @spec handle(%{anlist: any, header: %{qr: any}, qdlist: nonempty_maybe_improper_list}, any) ::
          %{anlist: [map], header: %{qr: false}, qdlist: []}
  def handle(record, _cl) do
    my_public_ip = {35, 202, 252, 226}

    Logger.info(fn -> "#{inspect(record)}" end)
    query = hd(record.qdlist)

    answer_prototype = %{record | qdlist: [], anlist: [], header: %{record.header | qr: true, aa: true, rd: false}}

    case query.domain |> List.to_string() do
      "gaia20.com" ->
        answer_data = case query.type do
          :a -> my_public_ip
          :txt -> ["gaia20-v0.0.1"]
          :soa -> generate_soa(record)
          :ns -> generate_ns(record)
          _ -> nil
        end

        answer_resource = %DNS.Resource{
          domain: query.domain,
          class: query.class,
          type: query.type,
          ttl: 60,
          data: answer_data
        }

        %{answer_prototype | anlist: [answer_resource]}
      target -> case Gaia20.Data.get(target) do
        :nx ->
          IO.inspect(:error)
          %{answer_prototype | header: %{answer_prototype.header | rcode: 3}}
        {:redirect, redirect} ->
          IO.inspect(:good)
          answer_data = case query.type do
            :a -> my_public_ip
            :txt -> [redirect]
            _ -> nil
          end

          answer_resource = %DNS.Resource{
            domain: query.domain,
            class: query.class,
            type: query.type,
            ttl: 0,
            data: answer_data
          }

          %{answer_prototype | anlist: [answer_resource]}
      end
    end
  end
end
