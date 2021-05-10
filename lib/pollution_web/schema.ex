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
  end

  input_object :coords_input do
    field(:latitude, non_null(:float))
    field(:longitude, non_null(:float))
  end

  input_object :add_station_input do
    field(:name, non_null(:string))
    field(:coords, non_null(:coords_input))
  end

  query do
    field :stations, non_null(list_of(non_null(:station))) do
      resolve(&Resolvers.list_stations/2)
    end
  end

  mutation do
    field :add_station, non_null(:station) do
      arg(:input, non_null(:add_station_input))
      resolve(&Resolvers.add_station/2)
    end
  end
end
