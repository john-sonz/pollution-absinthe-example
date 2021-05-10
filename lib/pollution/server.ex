defmodule Pollution.Server do
  use GenServer

  alias Pollution.Server.DataMonitor

  defp server() do
    :pollution_server
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: server())
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

  def handle_state_update(updated_state, prev_state) do
    case updated_state do
      {:ok, state} -> {:ok, state}
      {:error, reason} -> {{:error, reason}, prev_state}
    end
  end
end
