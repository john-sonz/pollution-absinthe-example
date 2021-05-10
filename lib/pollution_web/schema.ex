defmodule PollutionWeb.Schema do
  use Absinthe.Schema

  query do
    field :ping, non_null(:string) do
      resolve(fn _, _ -> {:ok, "pong"} end)
    end
  end

  mutation do
    field :ping, non_null(:string) do
      resolve(fn _, _ -> {:ok, "pong"} end)
    end
  end

  subscription do
    field :pinged, non_null(:string) do
      config(fn _, _ ->
        {:ok, topic: "pings"}
      end)

      trigger(:ping, topic: fn _ -> "pings" end)
    end
  end
end
