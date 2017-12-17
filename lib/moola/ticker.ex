defmodule Moola.Ticker do
  use Moola, :schema
  alias Moola.Ticker

  schema "ticks" do
    field :symbol, Moola.Enum.Symbol
    field :price, :float
    field :volume_60s, :float
    field :hour, :integer
    field :minute, :integer
    field :day_of_week, :integer
    field :timestamp, :utc_datetime
  end

  def changeset(%Ticker{} = ticker, attrs, %{"type" => "ticker"} = msg_attrs) do
    attrs = case DateTime.from_iso8601(msg_attrs["time"]) do
      {:ok, dt, _} -> 
        attrs
        |> Map.put_new(:timestamp, dt)
        |> Map.put_new(:hour, dt.hour)
        |> Map.put_new(:minute, dt.minute)
        |> Map.put_new(:day_of_week, Date.day_of_week(dt))
      _ -> 
        attrs
    end

    attrs = attrs
    |> Map.put(:symbol, msg_attrs |> Map.get("product_id") |> symbolize)
    |> Map.put(:price, msg_attrs |> Map.get("price"))

    changeset(ticker, attrs)
  end

  def changeset(%Ticker{} = ticker, attrs) do
    ticker
    |> cast(attrs, [:symbol, :price, :volume_60s, :hour, :minute, :day_of_week, :timestamp])
    |> validate_required([:symbol, :price, :volume_60s, :hour, :minute, :day_of_week, :timestamp])
  end
end
