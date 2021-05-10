defmodule Pollution.Server.DataMonitor do
  defstruct coords: %{}, measurements: %{}

  @type station_name :: String.t()
  @type station_coords :: {number(), number()}
  @type station_id :: station_name() | station_coords()
  @type measurements :: %{{DateTime.t(), String.t()} => number()}

  @type t :: %__MODULE__{
          coords: %{station_name() => station_coords()},
          measurements: %{station_coords() => measurements()}
        }

  @spec add_station(t(), station_name(), station_coords()) :: {:ok, t()} | {:error, atom()}
  def add_station(%__MODULE__{} = monitor, name, coords) do
    if station_exists?(monitor, name) or station_exists?(monitor, coords) do
      {:error, :station_already_exists}
    else
      monitor =
        monitor
        |> Map.update!(:coords, &Map.put(&1, name, coords))
        |> Map.update!(:measurements, &Map.put(&1, coords, %{}))

      {:ok, monitor}
    end
  end

  @spec add_value(t(), station_id(), DateTime.t(), String.t(), number()) ::
          {:ok, t()} | {:error, atom()}
  def add_value(%__MODULE__{} = monitor, station_id, datetime, type, value) do
    case get_one_value(monitor, station_id, datetime, type) do
      {:ok, _} ->
        {:error, :measurement_already_added}

      {:error, _} ->
        update_measurements(monitor, station_id, &Map.put(&1, {datetime, type}, value))
    end
  end

  @spec remove_value(t(), station_id(), DateTime.t(), String.t()) :: {:ok, t()} | {:error, atom()}
  def remove_value(%__MODULE__{} = monitor, station_id, datetime, type) do
    update_measurements(monitor, station_id, &Map.delete(&1, {datetime, type}))
  end

  @spec get_one_value(t(), station_id(), DateTime.t(), String.t()) ::
          {:ok, number()} | {:error, atom()}
  def get_one_value(%__MODULE__{} = monitor, station_id, datetime, type) do
    with {:ok, {measurements, _}} <- get_measurements(monitor, station_id) do
      case Map.fetch(measurements, {datetime, type}) do
        :error -> {:error, :measurement_not_found}
        {:ok, value} -> {:ok, value}
      end
    end
  end

  @spec get_station_mean(t(), station_id(), String.t()) ::
          {:ok, number() | nil} | {:error, atom()}
  def get_station_mean(%__MODULE__{} = monitor, station_id, target_type) do
    with {:ok, {measurements, _}} <- get_measurements(monitor, station_id) do
      mean =
        :maps.filter(fn {_, type}, _ -> type == target_type end, measurements)
        |> Map.values()
        |> arithmetic_mean()

      {:ok, mean}
    end
  end

  @spec get_daily_mean(t(), DateTime.t(), String.t()) :: number() | nil
  def get_daily_mean(%__MODULE__{measurements: measurements}, target_datetime, target_type) do
    measurements
    |> Enum.map(fn {_, ms} ->
      Enum.filter(ms, fn {{datetime, type}, _} ->
        target_type == type and same_day?(datetime, target_datetime)
      end)
    end)
    |> Enum.map(&Keyword.values/1)
    |> List.flatten()
    |> arithmetic_mean()
  end

  @spec get_area_mean(t(), station_id(), number(), String.t()) ::
          {:ok, number() | nil} | {:error, atom()}
  def get_area_mean(
        %__MODULE__{measurements: measurements} = monitor,
        station_id,
        radius,
        target_type
      ) do
    with {:ok, {_, center_coords}} <- get_measurements(monitor, station_id) do
      mean =
        measurements
        |> Enum.filter(fn {coords, _} -> get_distance(center_coords, coords) <= radius end)
        |> Enum.map(fn {_, ms} ->
          Enum.filter(ms, fn {{_, type}, _} -> type == target_type end)
        end)
        |> Enum.map(&Keyword.values/1)
        |> List.flatten()
        |> arithmetic_mean()

      {:ok, mean}
    end
  end

  @spec get_measurements(t(), station_id()) ::
          {:ok, {measurements(), station_coords()}} | {:error, atom()}
  defp get_measurements(%__MODULE__{} = monitor, {_lat, _lng} = coords) do
    if station_exists?(monitor, coords) do
      {:ok, {monitor.measurements[coords], coords}}
    else
      {:error, :station_not_found}
    end
  end

  defp get_measurements(%__MODULE__{} = monitor, name) when is_binary(name) do
    if station_exists?(monitor, name) do
      coords = monitor.coords[name]
      {:ok, {monitor.measurements[coords], coords}}
    else
      {:error, :station_not_found}
    end
  end

  @spec update_measurements(t(), station_id(), (measurements() -> measurements())) ::
          {:ok, t()} | {:error, atom()}
  defp update_measurements(%__MODULE__{} = monitor, station_id, update_fn) do
    with {:ok, {_, key}} <- get_measurements(monitor, station_id) do
      {:ok, %{monitor | measurements: Map.update!(monitor.measurements, key, update_fn)}}
    end
  end

  defp station_exists?(%__MODULE__{} = monitor, {_lat, _lng} = coords) do
    Map.has_key?(monitor.measurements, coords)
  end

  defp station_exists?(%__MODULE__{} = monitor, name) when is_binary(name) do
    Map.has_key?(monitor.coords, name)
  end

  @spec arithmetic_mean([number()]) :: number() | nil
  defp arithmetic_mean([]), do: nil

  defp arithmetic_mean(list) do
    {sum, count} = Enum.reduce(list, {0, 0}, fn val, {s, c} -> {s + val, c + 1} end)
    sum / count
  end

  @spec same_day?(DateTime.t(), DateTime.t()) :: boolean()
  defp same_day?(%DateTime{} = date1, %DateTime{} = date_2) do
    date1.year == date_2.year and
      date1.month == date_2.month and
      date1.day == date_2.day
  end

  @spec get_distance(station_coords(), station_coords()) :: number()
  defp get_distance({x1, y1}, {x2, y2}) do
    :math.sqrt(:math.pow(x1 - x2, 2) + :math.pow(y1 - y2, 2))
  end
end
