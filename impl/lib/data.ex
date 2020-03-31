defmodule Gaia20.Data do
  use Agent

  def start_link(:ok) do
    data = us_data_from_csv()
    |> Enum.flat_map(&dns_entries/1)
    |> Enum.into(%{})

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
    |> Enum.map(fn {k, {:redirect, v}} ->
      ~s(<tr><td><a href="http://#{k}">#{k}</a></td><td><a href="#{v}">#{v}</a></td></tr>)
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

  def us_data_from_csv() do
    "../us.csv"
    |> Path.expand(__DIR__)
    |> File.stream!
    |> CSV.decode
    |> Stream.drop(1)
    |> Stream.map(fn {:ok, [iso, name, auth_name, auth_homepage, covid_homepage, covid_homepage_lang]} ->
      %{
        iso: iso,
        name: name,
        auth_name: auth_name,
        auth_homepage: auth_homepage,
        covid_homepage: covid_homepage
      }
    end)
  end

  def dns_entries(%{iso: iso, name: name, auth_homepage: auth_homepage, covid_homepage: covid_homepage}) do
    keyed_name = name |> String.downcase() |> String.replace(" ", "_")

    [
      {"pubhealth.#{iso |> String.downcase}.us.gaia20.com", {:redirect, auth_homepage}},
      {"pubhealth.#{keyed_name}.us.gaia20.com", {:redirect, auth_homepage}},
      {"covid19.pubhealth.#{iso |> String.downcase}.us.gaia20.com", {:redirect, covid_homepage}},
      {"covid19.pubhealth.#{keyed_name}.us.gaia20.com", {:redirect, covid_homepage}},
    ]
  end
end
