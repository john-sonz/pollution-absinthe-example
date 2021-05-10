defmodule PollutionWeb.Resolvers do
  alias Pollution.Server

  def list_stations(_args, _ctx) do
    {:ok, Server.list_stations()}
  end

  def add_station(
        %{input: %{name: name, coords: %{latitude: lat, longitude: lng}}},
        _ctx
      ) do
    with :ok <- Server.add_station(name, {lat, lng}) do
      {:ok, %{name: name, coords: {lat, lng}}}
    end
  end

  def list_station_measurements(%{name: name}, _args, _ctx) do
    Server.list_station_measurements(name)
  end
end
