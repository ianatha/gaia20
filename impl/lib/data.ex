defmodule Gaia20.Data do
  use Agent

  def start_link(:ok) do
    us_data = us_data_from_csv()
    |> Enum.flat_map(& dns_entries(".us", &1))

    world_data = world_data_from_csv()
    |> Enum.flat_map(& dns_entries("", &1))

    data = (world_data ++ us_data) |> Enum.into(%{})

    Agent.start_link(fn -> data end, name: __MODULE__)
  end

  def get(key) do
    Agent.get(__MODULE__, fn state -> Map.get(state, key, :nx) end)
  end

  def all() do
    Agent.get(__MODULE__, & &1)
  end

  def to_html(entries) do
    entries_rows = (entries
    |> Enum.sort_by(fn {k, _} ->
      k |> String.split(".") |> Enum.reverse()
    end)
    |> Enum.map(fn {k, {:redirect, v}} ->
      ~s(<tr><td><a href="http://#{k}">#{k}</a></td><td>#{v}</td></tr>)
    end)
    |> Enum.join())

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
    |> File.stream!
    |> CSV.decode
    |> Stream.drop(1)
    |> Stream.map(
      fn {:ok, [iso2, _iso3, name, _auth_name, auth_homepage, covid_homepage, _covid_homepage_lang, _subregion, _regionalblocs, _population, chiefexec, _ceremonial_chiefexec, taxauth, legis]} ->
        %{
          iso: iso2,
          name: name,
          pubhealth: auth_homepage,
          pubhealth_covid19: covid_homepage,
          chiefexec: chiefexec,
          taxauth: taxauth,
          legis: legis
        }
      end
    )
  end

  def us_data_from_csv() do
    "../us.csv"
    |> Path.expand(__DIR__)
    |> File.stream!
    |> CSV.decode
    |> Stream.drop(1)
    |> Stream.map(fn {:ok, [iso, name, _pubhealth_name, pubhealth, pubhealth_covid19, _covid_homepage_lang, chiefexec, _c1, _c2, _state_or_territory, taxauth, legis]} ->
      %{
        iso: iso,
        name: name,
        pubhealth: pubhealth,
        pubhealth_covid19: pubhealth_covid19,
        chiefexec: chiefexec,
        taxauth: taxauth,
        legis: legis
      }
    end)
  end

  def dns_entries(suffix, %{iso: iso, name: name, pubhealth: pubhealth, pubhealth_covid19: pubhealth_covid19, chiefexec: chiefexec, taxauth: taxauth, legis: legis}) do
    names = [
      (iso |> String.downcase) <> suffix,
      (name |> String.downcase() |> String.replace(" ", "_")) <> suffix
    ]

    names
    |> Enum.flat_map(fn name ->
      [
        {"pubhealth.#{name}.gaia20.com", {:redirect, pubhealth}},
        {"covid19.pubhealth.#{name}.gaia20.com", {:redirect, pubhealth_covid19}},
        {"chiefexec.#{name}.gaia20.com", {:redirect, chiefexec}},
        {"taxauth.#{name}.gaia20.com", {:redirect, taxauth}},
        {"legis.#{name}.gaia20.com", {:redirect, legis}},
      ] |> Enum.filter(fn {_k, {:redirect, v}} -> v != "" end)
    end)
  end
end
