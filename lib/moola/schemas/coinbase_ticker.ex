defmodule Moola.CoinbaseTicker do
  use Moola, :schema
  alias Moola.CoinbaseTicker

  schema "coinbase_ticks" do
    field :symbol, Moola.Enum.Symbol
    field :buy_price, :decimal
    field :sell_price, :decimal
    field :spot_price, :decimal

    field :day_of_week, :integer
    field :hour, :integer
    field :latency, :integer
    field :minute, :integer
    field :timestamp, :utc_datetime
  end

  @doc false
  def changeset(%CoinbaseTicker{} = coinbase_ticker, attrs) do
    coinbase_ticker
    |> cast(attrs, [:symbol, :buy_price, :spot_price, :sell_price, :latency, :hour, :minute, :day_of_week, :timestamp])
    |> validate_required([:symbol, :buy_price, :spot_price, :sell_price, :latency, :hour, :minute, :day_of_week, :timestamp])
  end
end

defimpl Poison.Encoder, for: Moola.CoinbaseTicker do
  use Moola, :encoder
  alias Moola.CoinbaseTicker
  alias Decimal, as: D

  def encode(%CoinbaseTicker{} = tick, options \\ []) do
    %{
      id: tick.id,
      symbol: tick.symbol,
      buy_price: tick.buy_price |> D.to_float,
      sell_price: tick.sell_price |> D.to_float,
      spot_price: tick.spot_price |> D.to_float,
      latency: tick.latency,
      timestamp: tick.timestamp
    }
    |> Poison.Encoder.encode(options)
  end

end