defmodule Gaia20.DNSServer do
  @moduledoc """
  Example implementing DNS.Server behaviour
  """
  @behaviour Gaia20.GenericDNSServer

  require Logger
  use Gaia20.GenericDNSServer

  def generate_soa(record) do
    {'dns1.gaia20.org', 'community.gaia20.com', 2018110203, 86400, 5, 86400, 5}
  end

  def generate_ns(record) do
    'dns1.gaia20.org'
  end

  def handle(record, _cl) do
    my_public_ip = {35, 202, 252, 226}

    Logger.info(fn -> "#{inspect(record)}" end)
    query = hd(record.qdlist)

    answer_prototype = %{record | anlist: [], header: %{record.header | qr: true, aa: true, rd: false}}

    case query.domain |> List.to_string() do
      "gaia20.com" ->
        answer_data = case query.type do
          :a -> my_public_ip
          :txt -> ["gaia20-v0.0.1"]
          :soa -> generate_soa(record)
          :ns -> generate_ns(record)
          _ -> nil
        end

        case answer_data do
          nil ->
            %{answer_prototype | header: %{answer_prototype.header | rcode: 3}}
          answer_data ->
            answer_resource = %DNS.Resource{
              domain: query.domain,
              class: query.class,
              type: query.type,
              ttl: 60,
              data: answer_data
            }
            %{answer_prototype | anlist: [answer_resource]}
        end
      target -> case Gaia20.Data.get(target) do
        :nx ->
          IO.inspect(:error)
          %{answer_prototype | header: %{answer_prototype.header | rcode: 3}}
        {:redirect, redirect, _aliasing} ->
          answer_data = case query.type do
            :a -> my_public_ip
            :txt -> [redirect]
            _ -> nil
          end

          case answer_data do
            nil ->
              %{answer_prototype | header: %{answer_prototype.header | rcode: 3}}
            answer_data ->
              answer_resource = %DNS.Resource{
                domain: query.domain,
                class: query.class,
                type: query.type,
                ttl: 60,
                data: answer_data
              }
              %{answer_prototype | anlist: [answer_resource]}
          end
      end
    end
  end
end
