defmodule Moola.Ticker do
  use Moola, :schema
  alias Moola.Ticker

  schema "ticks" do
    field :symbol, Moola.Enum.Symbol
    field :price, :decimal
    field :max_price, :decimal
    field :min_price, :decimal
    field :volume, :decimal
    field :usd_volume, :decimal
    field :hour, :integer
    field :minute, :integer
    field :day_of_week, :integer
    field :timestamp, :utc_datetime
  end

  def changeset(%Ticker{} = ticker, attrs, %{"type" => type} = msg_attrs) when type in ["ticker", "match"] do
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
    |> cast(attrs, [:symbol, :price, :max_price, :min_price, :volume, :usd_volume, :hour, :minute, :day_of_week, :timestamp])
    |> validate_required([:symbol, :price, :volume, :hour, :minute, :day_of_week, :timestamp])
  end
end

defimpl Poison.Encoder, for: Moola.Ticker do
  use Moola, :encoder
  alias Decimal, as: D
  alias Moola.Ticker

  def encode(%Ticker{} = tick, options \\ []) do
    %{
      id: tick.id,
      symbol: tick.symbol,
      price: tick.price |> D.to_float,
      volume: tick.volume |> D.to_float,
      usdVolume: tick.usd_volume |> D.to_float,
      timestamp: tick.timestamp
    }
    |> Poison.Encoder.encode(options)
  end

end