defmodule Moola.BinanceTicker do
  use Moola, :schema
  alias Moola.BinanceTicker

  schema "binance_ticks" do
    field :symbol, Moola.Enum.BinanceSymbol
    field :price, :decimal
    field :max_price, :decimal
    field :min_price, :decimal
    field :volume, :decimal
    field :usd_volume, :decimal
    field :btc_volume, :decimal
    field :hour, :integer
    field :minute, :integer
    field :day_of_week, :integer
    field :timestamp, :utc_datetime
  end

  def changeset(%BinanceTicker{} = ticker, attrs, %{"E" => time, "s" => symbol, "p" => price}) do
    attrs = case DateTime.from_unix(time, :millisecond) do
      {:ok, dt} -> 
        attrs
        |> Map.put_new(:timestamp, dt)
        |> Map.put_new(:hour, dt.hour)
        |> Map.put_new(:minute, dt.minute)
        |> Map.put_new(:day_of_week, Date.day_of_week(dt))
      _ -> 
        attrs
    end

    attrs = attrs
    |> Map.put(:symbol, symbol |> symbolize)
    |> Map.put(:price, price)

    changeset(ticker, attrs)
  end

  def changeset(%BinanceTicker{} = ticker, attrs) do
    ticker
    |> cast(attrs, [:symbol, :price, :max_price, :min_price, :volume, :btc_volume, :usd_volume, :hour, :minute, :day_of_week, :timestamp])
    |> validate_required([:symbol, :price, :volume, :hour, :minute, :day_of_week, :timestamp])
  end
end

defimpl Poison.Encoder, for: Moola.BinanceTicker do
  use Moola, :encoder
  alias Decimal, as: D
  alias Moola.BinanceTicker

  def encode(%BinanceTicker{} = tick, options \\ []) do
    %{
      id: tick.id,
      symbol: tick.symbol,
      price: tick.price |> to_float,
      volume: tick.volume |> to_float,
      btcVolume: tick.btc_volume |> to_float,
      usdVolume: tick.usd_volume |> to_float,
      timestamp: tick.timestamp
    }
    |> Poison.Encoder.encode(options)
  end

  defp to_float(decimal) do
    case decimal do
      nil -> nil
      num -> num |> D.to_float
    end
  end
end