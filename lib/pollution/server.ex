defmodule Pollution.Server do
  use GenServer

  alias Pollution.Server.{DataMonitor, Seeds}

  defp server() do
    :pollution_server
  end

  def start_link() do
    result = GenServer.start_link(__MODULE__, [], name: server())
    spawn(&Seeds.seed_server/0)
    result
  end

  @impl true
  def init(_) do
    {:ok, %DataMonitor{}}
  end

  @spec add_station(DataMonitor.station_name(), DataMonitor.station_coords()) ::
          :ok | {:error, atom()}
  def add_station(name, coords) do
    GenServer.call(server(), {:add_station, name, coords})
  end

  @spec add_value(DataMonitor.station_id(), DateTime.t(), String.t(), number()) ::
          :ok | {:error, atom()}
  def add_value(station_id, datetime, type, value) do
    GenServer.call(server(), {:add_value, station_id, datetime, type, value})
  end

  @spec remove_value(DataMonitor.station_id(), DateTime.t(), String.t()) :: :ok | {:error, atom()}
  def remove_value(station_id, datetime, type) do
    GenServer.call(server(), {:remove_value, station_id, datetime, type})
  end

  @spec get_one_value(DataMonitor.station_id(), DateTime.t(), String.t()) ::
          {:ok, number()} | {:error, atom()}
  def get_one_value(station_id, datetime, type) do
    GenServer.call(server(), {:get_one_value, station_id, datetime, type})
  end

  @spec get_station_mean(DataMonitor.station_id(), String.t()) ::
          {:ok, number() | nil} | {:error, atom()}
  def get_station_mean(station_id, target_type) do
    GenServer.call(server(), {:get_station_mean, station_id, target_type})
  end

  @spec get_daily_mean(DateTime.t(), String.t()) :: number() | nil
  def get_daily_mean(target_datetime, target_type) do
    GenServer.call(server(), {:get_daily_mean, target_datetime, target_type})
  end

  @spec get_area_mean(DataMonitor.station_id(), number(), String.t()) ::
          {:ok, number() | nil} | {:error, atom()}
  def get_area_mean(station_id, radius, target_type) do
    GenServer.call(server(), {:get_area_mean, station_id, radius, target_type})
  end

  @spec list_stations() :: list()
  def list_stations() do
    GenServer.call(server(), :list_stations)
  end

  @spec list_station_measurements(DataMonitor.station_id()) ::
          {:ok, [map()]} | {:error, atom()}
  def list_station_measurements(station_id) do
    GenServer.call(server(), {:list_station_measurements, station_id})
  end

  @spec get_station(DataMonitor.station_id()) :: {:ok, map()} | {:error, atom()}
  def get_station(station_id) do
    GenServer.call(server(), {:get_station, station_id})
  end

  @impl true
  def handle_call({:add_station, name, coords}, _from, state) do
    {reply, new_state} =
      state
      |> DataMonitor.add_station(name, coords)
      |> handle_state_update(state)

    {:reply, reply, new_state}
  end

  def handle_call({:add_value, station_id, datetime, type, value}, _from, state) do
    {reply, new_state} =
      state
      |> DataMonitor.add_value(station_id, datetime, type, value)
      |> handle_state_update(state)

    {:reply, reply, new_state}
  end

  def handle_call({:remove_value, station_id, datetime, type}, _from, state) do
    {reply, new_state} =
      state
      |> DataMonitor.remove_value(station_id, datetime, type)
      |> handle_state_update(state)

    {:reply, reply, new_state}
  end

  def handle_call({:get_one_value, station_id, datetime, type}, _from, state) do
    {:reply, DataMonitor.get_one_value(state, station_id, datetime, type), state}
  end

  def handle_call({:get_station_mean, station_id, target_type}, _from, state) do
    {:reply, DataMonitor.get_station_mean(state, station_id, target_type), state}
  end

  def handle_call({:get_daily_mean, target_datetime, target_type}, _from, state) do
    {:reply, DataMonitor.get_daily_mean(state, target_datetime, target_type), state}
  end

  def handle_call({:get_area_mean, station_id, radius, target_type}, _from, state) do
    {:reply, DataMonitor.get_area_mean(state, station_id, radius, target_type), state}
  end

  def handle_call(:list_stations, _from, state) do
    stations =
      state.coords
      |> Enum.map(fn {name, coords} -> %{name: name, coords: coords} end)

    {:reply, stations, state}
  end

  def handle_call({:list_station_measurements, station_id}, _from, state) do
    reply =
      with {:ok, {ms, _}} <- DataMonitor.get_measurements(state, station_id) do
        measurements =
          Enum.map(ms, fn {{dt, type}, val} -> %{datetime: dt, type: type, value: val} end)

        {:ok, measurements}
      end

    {:reply, reply, state}
  end

  def handle_call({:get_station, {_lat, _lng} = coords}, _from, state) do
    reply =
      if Map.has_key?(state.measurements, coords) do
        state.coords
        |> Enum.find_value({:error, :station_not_found}, fn {name, c} ->
          if c == coords,
            do: {:ok, %{name: name, coords: coords}},
            else: false
        end)
      else
        {:error, :station_not_found}
      end

    {:reply, reply, state}
  end

  def handle_call({:get_station, name}, _from, state) do
    reply =
      if Map.has_key?(state.coords, name) do
        {:ok, %{name: name, coords: state.coords[name]}}
      else
        {:error, :station_not_found}
      end

    {:reply, reply, state}
  end

  defp handle_state_update(updated_state, prev_state) do
    case updated_state do
      {:ok, state} -> {:ok, state}
      {:error, reason} -> {{:error, reason}, prev_state}
    end
  end
end
