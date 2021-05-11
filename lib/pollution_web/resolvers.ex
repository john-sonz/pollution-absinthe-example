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

  def add_value(%{input: %{name: name} = input}, _ctx), do: do_add_value(name, input)

  def add_value(%{input: %{coords: %{latitude: lat, longitude: lng}} = input}, _ctx) do
    do_add_value({lat, lng}, input)
  end

  def add_value(_, _), do: {:error, "One of fields name or coords is required"}

  defp do_add_value(station_id, %{datetime: dt, type: type, value: val} = input) do
    with :ok <- Server.add_value(station_id, dt, type, val), do: {:ok, input}
  end

  def get_station(args, _ctx) do
    case args do
      %{name: name} -> Server.get_station(name)
      %{coords: coords} -> Server.get_station({coords.latitude, coords.longitude})
      _ -> {:error, "One of fields name or coords is required"}
    end
  end

  def get_station_mean(%{name: name}, %{type: type}, _ctx) do
    Server.get_station_mean(name, type)
  end

  def get_daily_mean(args, _ctx) do
    {:ok, Server.get_daily_mean(args.datetime, args.type)}
  end

  def get_area_mean(%{radius: radius} = args, _ctx) when radius >= 0 do
    Server.get_area_mean({args.coords.latitude, args.coords.longitude}, args.radius, args.type)
  end

  def get_area_mean(_, _), do: {:error, :invalid_radius}
end
