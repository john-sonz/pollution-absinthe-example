defmodule Pollution.Server.Seeds do
  alias Pollution.Server

  @stations [
    %{name: "Foo", coords: {20, 20}},
    %{name: "Bar", coords: {10, 30}}
  ]

  @measurements [
    %{station: "Foo", type: "PM10", value: 125.3, datetime: DateTime.utc_now()},
    %{station: "Foo", type: "TEMP", value: 23.8, datetime: DateTime.utc_now()},
    %{
      station: "Foo",
      type: "PM10",
      value: 124.3,
      datetime: DateTime.utc_now() |> DateTime.add(60 * 60)
    },
    %{
      station: "Foo",
      type: "TEMP",
      value: 24.4,
      datetime: DateTime.utc_now() |> DateTime.add(60 * 60)
    },
    %{station: "Bar", type: "PM10", value: 136.1, datetime: DateTime.utc_now()},
    %{station: "Bar", type: "TEMP", value: 25.2, datetime: DateTime.utc_now()}
  ]

  def seed_server() do
    @stations
    |> Enum.each(&Server.add_station(&1.name, &1.coords))

    @measurements
    |> Enum.each(&Server.add_value(&1.station, &1.datetime, &1.type, &1.value))
  end
end
