defmodule PollutionWeb.Schema do
  use Absinthe.Schema

  alias PollutionWeb.Resolvers

  import_types(Absinthe.Type.Custom)

  object :coords do
    field(:latitude, non_null(:float))
    field(:longitude, non_null(:float))
  end

  object :measurement do
    field(:datetime, non_null(:datetime))
    field(:type, non_null(:string))
    field(:value, non_null(:float))
  end

  object :station do
    field(:coords, non_null(:coords)) do
      resolve(fn %{coords: {lat, lng}}, _args, _ctx ->
        {:ok, %{latitude: lat, longitude: lng}}
      end)
    end

    field(:name, non_null(:string))

    field(:measurements, non_null(list_of(non_null(:measurement)))) do
      resolve(&Resolvers.list_station_measurements/3)
    end

    field(:mean, :float) do
      arg(:type, non_null(:string))
      resolve(&Resolvers.get_station_mean/3)
    end
  end

  input_object :coords_input do
    field(:latitude, non_null(:float))
    field(:longitude, non_null(:float))
  end

  input_object :add_station_input do
    field(:name, non_null(:string))
    field(:coords, non_null(:coords_input))
  end

  input_object :add_value_input do
    field(:name, :string)
    field(:coords, :coords_input)
    field(:datetime, non_null(:datetime))
    field(:type, non_null(:string))
    field(:value, non_null(:float))
  end

  query do
    field :stations, non_null(list_of(non_null(:station))) do
      resolve(&Resolvers.list_stations/2)
    end

    field :station, non_null(:station) do
      arg(:name, :string)
      arg(:coords, :coords_input)
      resolve(&Resolvers.get_station/2)
    end

    field :daily_mean, :float do
      arg(:datetime, non_null(:datetime))
      arg(:type, non_null(:string))
      resolve(&Resolvers.get_daily_mean/2)
    end

    field :area_mean, :float do
      arg(:coords, non_null(:coords_input))
      arg(:radius, non_null(:float))
      arg(:type, non_null(:string))
      resolve(&Resolvers.get_area_mean/2)
    end
  end

  mutation do
    field :add_station, non_null(:station) do
      arg(:input, non_null(:add_station_input))
      resolve(&Resolvers.add_station/2)
    end

    field :add_value, non_null(:measurement) do
      arg(:input, non_null(:add_value_input))
      resolve(&Resolvers.add_value/2)
    end
  end

  def station_name_topic(name), do: "station:#{name}"
  def station_coords_topic(coords), do: "station:(#{coords.latitude}:#{coords.longitude})"

  subscription do
    field :station_added, non_null(:station) do
      config(fn _args, _ctx ->
        {:ok, topic: "station:new"}
      end)

      trigger(:add_station, topic: fn _ -> "station:new" end)
    end

    field :value_added, non_null(:measurement) do
      arg(:station_name, non_null(:string))
      arg(:station_coords, non_null(:coords_input))

      config(fn %{station_name: name, station_coords: coords}, _ ->
        {:ok, topic: [station_name_topic(name), station_coords_topic(coords)]}
      end)

      trigger(:add_value,
        topic: fn ms ->
          case ms do
            %{name: name} -> station_name_topic(name)
            %{coords: coords} -> station_coords_topic(coords)
            _ -> ""
          end
        end
      )
    end
  end
end
