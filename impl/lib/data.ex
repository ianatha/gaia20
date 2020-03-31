defmodule Gaia20.Data do
  use Agent

  def start_link(:ok) do
    data = data_from_yaml()

    Agent.start_link(fn -> data end, name: __MODULE__)
  end

  def get(key) do
    Agent.get(__MODULE__, fn state -> Map.get(state, key, :nx) end)
  end

  def all() do
    Agent.get(__MODULE__, & &1)
  end

  def to_html(entries) do
    entries_rows =
      entries
      |> Enum.sort_by(fn {k, _} ->
        k |> String.split(".") |> Enum.reverse()
      end)
      |> Enum.map(fn {k, {:redirect, v}} ->
        ~s(<tr><td><a href="http://#{k}">#{k}</a></td><td>#{v}</td></tr>)
      end)
      |> Enum.join()

    """
      <html><body>
        <h1>gaia20.com all entries listing</h1>
        <table>
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

  @spec dns_entries(binary, %{
          chiefexec: any,
          iso: binary,
          legis: any,
          name: binary,
          pubhealth_covid19: any,
          pubhealth_web: any,
          taxauth: any
        }) :: [any]
  def dns_entries(suffix, %{
        iso: iso,
        name: name,
        pubhealth_web: pubhealth_web,
        pubhealth_covid19: pubhealth_covid19,
        chiefexec: chiefexec,
        taxauth: taxauth,
        legis: legis
      }) do
    names = [
      (iso |> String.downcase()) <> suffix,
      (name |> String.downcase() |> String.replace(" ", "_")) <> suffix
    ]

    names
    |> Enum.flat_map(fn name ->
      [
        {"pubhealth.#{name}.gaia20.com", {:redirect, pubhealth_web}},
        {"covid19.pubhealth.#{name}.gaia20.com", {:redirect, pubhealth_covid19}},
        {"chiefexec.#{name}.gaia20.com", {:redirect, chiefexec}},
        {"taxauth.#{name}.gaia20.com", {:redirect, taxauth}},
        {"legis.#{name}.gaia20.com", {:redirect, legis}}
      ]
      |> Enum.filter(fn {_k, {:redirect, v}} -> v != "" end)
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

  def jurisdiction_to_dns({name, data}, suffix \\ "") do
    {names, subsuffix} = case Map.has_key?(data, 'iso') do
      true -> {[
        (Map.get(data, 'iso') |> String.downcase()) <> suffix,
        (Map.get(data, 'name') |> String.downcase() |> String.replace(" ", "_")) <> suffix
      ], (Map.get(data, 'iso') |> String.downcase()) <> suffix}
      false -> {[""], ""}
    end

    this_jurisdiction_dns_records =
      names
      |> Enum.flat_map(fn name ->
        [
          {"pubhealth.#{name}gaia20.com",
           {:redirect, Map.get(data, 'pubhealth_web', "")}},
          {"covid19.pubhealth.#{name}gaia20.com",
           {:redirect, Map.get(data, 'pubhealth_covid19', "")}},
          {"chiefexec.#{name}gaia20.com", {:redirect, Map.get(data, 'chiefexec', "")}},
          {"taxauth.#{name}gaia20.com", {:redirect, Map.get(data, 'taxauth', "")}},
          {"legis.#{name}gaia20.com", {:redirect, Map.get(data, 'legis', "")}}
        ]
        |> Enum.filter(fn {_k, {:redirect, v}} -> v != "" end)
      end)

    this_jurisdiction_dns_records ++
      (Map.get(data, '_jurisdictions', []) |> Enum.flat_map(&jurisdiction_to_dns(&1, ".#{subsuffix}")))
  end

  def data_from_yaml() do
    :yamerl_constr.file("data.yml")
    |> hd
    |> mapify
    |> Enum.flat_map(&jurisdiction_to_dns/1)
  end
end
