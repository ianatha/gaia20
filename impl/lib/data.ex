defmodule Gaia20.Data do
  use Agent

  # defp sentix_receive() do
  #   receive do
  #     { _os_process_pid, { :fswatch, :file_event }, { _file_path, _event_list } } = event ->
  #       IO.puts("data.yaml refreshed")
  #       Gaia20.Data.refresh()
  #   end
  #   sentix_receive()
  # end

  def start_link(:ok) do
    data = data_from_yaml()

    res = Agent.start_link(fn -> data end, name: __MODULE__)

    # Task.start(fn ->
    #   Sentix.subscribe(:data_yaml)

    #   sentix_receive()
    # end)
  end

  def handle_cast(msg) do
    IO.inspect(msg)
  end

  def refresh() do
    Agent.get_and_update(__MODULE__, fn _state ->
      {:ok, data_from_yaml()}
    end)
  end

  def get(key) when is_bitstring(key) do
    Agent.get(__MODULE__, fn state -> Map.get(state, key, :nx) end)
  end

  def all() do
    Agent.get(__MODULE__, & &1)
  end

  def all_with_suffix(""), do: all()

  def all_with_suffix(suffix) do
    all()
    |> Enum.filter(fn {k, {:redirect, _, aliases}} ->
      entry_alias_matches = case aliases do
        :alias -> false # i'm an alias, i don't have aliases
        aliases when is_list(aliases) ->
          aliases |> Enum.any?(fn {:alias, aliasname} ->
            String.ends_with?(aliasname, "." <> suffix)
          end)
      end

      entry_alias_matches or String.ends_with?(k, "." <> suffix)
    end)
  end

  def aliases_to_html(h) do
    h |>
    Enum.map(fn {:alias, al} ->
      ~s(<a href="http://#{al}">#{al}</a>)
    end)
    |> Enum.join(", ")
  end

  def to_html(entries, suffix) do
    title = case suffix do
      "" -> "gaia20.com: All Entries Listing"
      _ -> "gaia20.com: #{suffix} Listing"
    end
    entries_rows =
      entries
      |> Enum.sort_by(fn {k, _} ->
        k |> String.split(".") |> Enum.reverse()
      end)
      |> Enum.map(fn {k, {:redirect, v, aliases}} ->
        case aliases do
          :alias -> ""
          _ -> ~s(
            <tr>
              <td>
                <a href="http://#{k}">
                  #{k}
                </a>
              </td>
              <td>
                #{aliases_to_html(aliases)}
              </td>
              <td>
                #{v}
              </td>
            </tr>)
        end
      end)
      |> Enum.join()

    """
      <html><body>
        <h1>#{title}</h1>
        <table>
        <tr>
          <td><b>Long DNS Name</b></td>
          <td><b>Normative DNS Name</b></td>
          <td><b>Target Page</b></td>
        </tr>
        #{entries_rows}
        </table>
      </body></html>
    """
  end

  def world_data_from_csv() do
    "../world.csv"
    |> Path.expand(__DIR__)
    |> File.stream!()
    |> CSV.decode()
    |> Stream.drop(1)
    |> Stream.map(fn {:ok,
                      [
                        iso2,
                        iso3,
                        name,
                        auth_name,
                        auth_homepage,
                        covid_homepage,
                        covid_homepage_lang,
                        _subregion,
                        _regionalblocs,
                        _population,
                        chiefexec,
                        _ceremonial_chiefexec,
                        taxauth,
                        legis
                      ]} ->
      %{
        iso: iso2,
        iso3: iso3,
        name: name,
        pubhealth: auth_name,
        pubhealth_web: auth_homepage,
        pubhealth_covid19: covid_homepage,
        pubhealth_covid19_lang: covid_homepage_lang,
        chiefexec: chiefexec,
        taxauth: taxauth,
        legis: legis
      }
    end)
  end

  def world_to_yaml() do
    origin = world_data_from_csv()

    origin
    |> Enum.map(fn country ->
      post_country = country |> Enum.filter(fn {k, v} -> v != "" end) |> Enum.into(%{})
      {country[:iso], post_country}
    end)
    |> Enum.sort()
  end

  def usa_to_yaml() do
    origin = us_data_from_csv()

    origin
    |> Enum.map(fn country ->
      post_country = country |> Enum.filter(fn {k, v} -> v != "" end) |> Enum.into(%{})
      {country[:iso], post_country}
    end)
    |> Enum.sort()
  end

  def us_data_from_csv() do
    "../us.csv"
    |> Path.expand(__DIR__)
    |> File.stream!()
    |> CSV.decode()
    |> Stream.drop(1)
    |> Stream.map(fn {:ok,
                      [
                        iso,
                        name,
                        pubhealth_name,
                        pubhealth,
                        pubhealth_covid19,
                        covid_homepage_lang,
                        chiefexec,
                        c1,
                        c2,
                        _state_or_territory,
                        taxauth,
                        legis
                      ]} ->
      %{
        iso: iso,
        name: name,
        pubhealth: pubhealth_name,
        pubhealth_web: pubhealth,
        pubhealth_covid19: pubhealth_covid19,
        pubhealth_covid19_lang: covid_homepage_lang,
        chiefexec: chiefexec,
        taxauth: taxauth,
        legis: legis,
        chiefexec_fn: c1,
        chiefexec_ln: c2
      }
    end)
  end

  def mapify([]) do
    %{}
  end

  def mapify([{k, v} | t]) do
    Map.merge(%{k => mapify(v)}, mapify(t))
  end

  def mapify(x) when is_list(x) do
    List.to_string(x)
  end

  def mapify(x) do
    x
  end

  def flatten_alias(:alias, _), do: :alias

  def flatten_alias([], _), do: []

  def flatten_alias([ h | t ], struct) do
    res = struct.(h)
    [ {:alias, res} ] ++ flatten_alias(t, struct)
  end

  def jurisdiction_to_dns({name, data}, suffix \\ "") do
    {names, subsuffix} = case Map.has_key?(data, 'iso') do
      true -> {[
        {(Map.get(data, 'iso') |> String.downcase()) <> suffix, :alias},
        {(Map.get(data, 'name') |> String.downcase() |> String.replace(" ", "_")) <> suffix,
          [
            (Map.get(data, 'iso') |> String.downcase()) <> suffix
          ]
        }
      ], (Map.get(data, 'iso') |> String.downcase()) <> suffix}
      false -> {[{"", []}], ""}
    end

    this_jurisdiction_dns_records =
      names
      |> Enum.flat_map(fn {name, name_type} ->
        [
          {
            "pubhealth.#{name}gaia20.com",
            {:redirect, Map.get(data, 'pubhealth_web', ""), flatten_alias(name_type, fn name -> "pubhealth.#{name}gaia20.com" end)}
          },
          {
            "covid19.pubhealth.#{name}gaia20.com",
            {:redirect, Map.get(data, 'pubhealth_covid19', ""), flatten_alias(name_type, fn name -> "covid19.pubhealth.#{name}gaia20.com" end)}
          },
          {
            "chiefexec.#{name}gaia20.com",
            {:redirect, Map.get(data, 'chiefexec', ""), flatten_alias(name_type, fn name -> "chiefexec.#{name}gaia20.com" end)}
          },
          {
            "taxauth.#{name}gaia20.com",
            {:redirect, Map.get(data, 'taxauth', ""), flatten_alias(name_type, fn name -> "taxauth.#{name}gaia20.com" end)}
          },
          {
            "legis.#{name}gaia20.com",
            {:redirect, Map.get(data, 'legis', ""), flatten_alias(name_type, fn name -> "legis.#{name}gaia20.com" end)}
          }
        ]
        |> Enum.filter(fn {_k, {:redirect, v, _nt}} -> v != "" end)
      end)

    this_jurisdiction_dns_records ++
      (Map.get(data, '_jurisdictions', []) |> Enum.flat_map(&jurisdiction_to_dns(&1, ".#{subsuffix}")))
  end

  def data_from_yaml() do
    :yamerl_constr.file("data.yml")
    |> hd
    |> mapify
    |> Enum.flat_map(&jurisdiction_to_dns/1)
    |> Enum.into(%{})
  end
end
