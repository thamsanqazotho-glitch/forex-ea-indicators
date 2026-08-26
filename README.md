# Forex EA - Multi Indicator (EMA, RSI, MACD)

A professional MQL5 Expert Advisor for MetaTrader 5 that combines three powerful technical indicators for automated forex trading.

## Features

✅ **Three-Indicator Confirmation System**
- EMA (Exponential Moving Average) - Trend Direction
- RSI (Relative Strength Index) - Momentum & Overbought/Oversold
- MACD (Moving Average Convergence Divergence) - Trend Confirmation

✅ **Smart Entry Logic**
- **BUY Signal**: Price > EMA (uptrend) + EMA trending up + RSI < 70 + MACD positive
- **SELL Signal**: Price < EMA (downtrend) + EMA trending down + RSI > 30 + MACD negative

✅ **Advanced Exit Strategies**
- MACD reversal detection for dynamic exits
- Fixed Take Profit & Stop Loss levels
- ATR-based dynamic S/L and T/P (optional)

✅ **Risk Management**
- Maximum drawdown protection
- Max concurrent trades limit
- Lot size control
- Position-based stop loss and take profit

✅ **Professional Features**
- Magic number for trade identification
- Detailed trade logging
- Multiple timeframe support
- Symbol-agnostic design

## Installation

1. **Copy the EA file** to your MetaTrader 5 directory:
   ```
   MetaTrader 5\MQL5\Experts\
   ```

2. **Compile the code** in MetaEditor (F7)

3. **Attach to Chart**:
   - Open any forex chart (EURUSD, GBPUSD, etc.)
   - Drag the EA from Navigator → Experts → ForexEA_Indicators onto the chart
   - Allow DLL imports and live trading

## Input Parameters

### Trading Parameters
- **LotSize**: 0.1 (Default) - Volume per trade
- **MagicNumber**: 123456 - Unique identifier for EA trades
- **MaxTrades**: 3 - Maximum concurrent open positions
- **MaxDrawdown**: 2.0 - Maximum drawdown % before stopping trades

### Indicator Settings
- **EMA_Period**: 20 (Default) - Faster trend detection
- **RSI_Period**: 14 (Standard) - Momentum measurement
- **MACD_Fast**: 12 (Standard) - Fast EMA
- **MACD_Slow**: 26 (Standard) - Slow EMA
- **MACD_Signal**: 9 (Standard) - Signal line

### Risk Management
- **RSI_Overbought**: 70 - Don't buy above this level
- **RSI_Oversold**: 30 - Don't sell below this level
- **TakeProfitPips**: 100 - Fixed TP distance
- **StopLossPips**: 50 - Fixed SL distance
- **UseATR**: true - Enable dynamic SL/TP using ATR
- **ATR_Period**: 14 - ATR calculation period

## How It Works

### Entry Logic Flow

```
┌─────────────────────────────────────┐
│   Check All Conditions Met          │
├─────────────────────────────────────┤
│ ✓ Price > EMA (Uptrend)             │
│ ✓ EMA Trending Up                   │
│ ✓ RSI < 70 (Not Overbought)         │
│ ✓ RSI > 40 (Momentum Confirmed)     │
│ ✓ MACD > Signal Line (Bullish)      │
│ ✓ MACD > 0 (Above Zero)             │
├─────────────────────────────────────┤
│   → OPEN BUY POSITION               │
└─────────────────────────────────────┘
```

**SELL Signal** follows the same logic in reverse.

### Exit Logic

1. **MACD Reversal**: Position closes when MACD crosses back below/above signal line
2. **Take Profit**: Automatically hit if price reaches T/P level
3. **Stop Loss**: Automatically hit if price reaches S/L level

## Customization Guide

### Adjust for Faster Trades (Scalping)
```
EMA_Period: 10
TakeProfitPips: 30
StopLossPips: 20
MaxTrades: 5
```

### Adjust for Swing Trading
```
EMA_Period: 50
TakeProfitPips: 200
StopLossPips: 100
MaxTrades: 1
```

### Adjust for Trend Following
```
EMA_Period: 100
RSI_Overbought: 80
RSI_Oversold: 20
UseATR: true
ATR_Period: 20
```

## Best Practices

1. **Backtest First**: Always backtest on historical data before live trading
2. **Forward Test**: Paper trade for 1-2 weeks before risking real money
3. **Monitor Regularly**: Check logs and performance daily
4. **Adjust to Market**: Update parameters based on market conditions
5. **Risk Management**: Start with small lot sizes (0.1 or 0.01)
6. **Use on Liquid Pairs**: Best performance on EURUSD, GBPUSD, USDJPY, AUDUSD

## Recommended Chart Setup

- **Timeframe**: M15 or M30 (4-hour data updates)
- **Pairs**: Major pairs (EURUSD, GBPUSD, USDJPY)
- **Trading Hours**: London and US sessions for best liquidity
- **Spread Consideration**: Ensure spread < 2 pips for profitability

## Indicator Interpretation

### EMA (20-period)
- **Above EMA**: Uptrend active
- **Below EMA**: Downtrend active
- **EMA Angle**: Steeper = Stronger trend

### RSI (14-period)
- **RSI > 70**: Overbought (caution on BUY)
- **RSI < 30**: Oversold (caution on SELL)
- **RSI 40-60**: Neutral zone
- **Divergence**: Price high but RSI low = Reversal signal

### MACD (12,26,9)
- **MACD > Signal**: Bullish momentum
- **MACD < Signal**: Bearish momentum
- **MACD > 0**: Above zero line = Strength
- **MACD Crossover**: Entry confirmation signal

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No trades opening | Check RSI levels, reduce MaxDrawdown limit |
| Too many trades | Reduce MaxTrades, tighten entry conditions |
| High losses | Increase StopLossPips, reduce LotSize |
| Missing entries | Lower RSI thresholds, shorten EMA period |
| Stuck in trades | Check MACD reversal logic, monitor charts |

## Performance Metrics to Track

- **Win Rate**: % of profitable trades (Target: >55%)
- **Profit Factor**: Gross profit / Gross loss (Target: >1.5)
- **Sharpe Ratio**: Risk-adjusted returns (Target: >1.0)
- **Max Drawdown**: Largest decline from peak (Limit: 10-20%)
- **Recovery Factor**: Net profit / Max Drawdown (Target: >3.0)

## Disclaimer

⚠️ **RISK WARNING**: Forex trading involves substantial risk. This EA is provided as-is for educational purposes. Always:
- Test thoroughly in a demo account first
- Start with minimal lot sizes
- Never risk more than 1-2% per trade
- Monitor trades actively
- Understand that past performance ≠ future results

## Support & Updates

For issues or improvements, refer to the GitHub repository:
🔗 [forex-ea-indicators](https://github.com/thamsanqazotho-glitch/forex-ea-indicators)

---

**Last Updated**: 2026-08-26  
**Version**: 1.00  
**Status**: Ready for Testing
