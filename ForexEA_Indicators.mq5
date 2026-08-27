//+------------------------------------------------------------------+
//|                        Forex EA - Multi Indicator                |
//|                    EMA, RSI, and MACD Combination                |
//|                    MANUAL CALCULATION VERSION                    |
//+------------------------------------------------------------------+

#property copyright "Copyright 2024"
#property link      "https://github.com/thamsanqazotho-glitch/forex-ea-indicators"
#property version   "1.03"

//--- Input Parameters
input double   LotSize = 0.1;              // Trade lot size
input int      EMA_Period = 20;            // EMA period
input int      RSI_Period = 14;            // RSI period
input int      MACD_Fast = 12;             // MACD Fast EMA
input int      MACD_Slow = 26;             // MACD Slow EMA
input int      MACD_Signal = 9;            // MACD Signal line

input double   RSI_Overbought = 70;        // RSI Overbought level
input double   RSI_Oversold = 30;          // RSI Oversold level

input int      TakeProfitPips = 100;       // Take Profit in pips
input int      StopLossPips = 50;          // Stop Loss in pips

input int      ATR_Period = 14;            // ATR period for dynamic SL/TP
input bool     UseATR = true;              // Use ATR for dynamic levels

input int      MagicNumber = 123456;       // Magic number for trades
input double   MaxDrawdown = 2.0;          // Max drawdown % allowed
input int      MaxTrades = 3;              // Maximum concurrent trades

//--- Global Variables
bool indicatorsReady = false;
double close[];
double high[];
double low[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Set arrays as series
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   
   Print("EA initialized successfully on ", _Symbol, " ", _Period);
   Print("Using MANUAL indicator calculation (no indicator handles)");
   Print("Account: Demo | Lot Size: ", LotSize);
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Copy price data
   int copied_close = CopyClose(_Symbol, _Period, 0, 100, close);
   int copied_high = CopyHigh(_Symbol, _Period, 0, 100, high);
   int copied_low = CopyLow(_Symbol, _Period, 0, 100, low);
   
   // Check if we have enough data
   if(copied_close < 50 || copied_high < 50 || copied_low < 50)
   {
      if(!indicatorsReady)
         Print("Loading data... Close:", copied_close, " High:", copied_high, " Low:", copied_low);
      return;
   }
   
   if(!indicatorsReady)
   {
      Print("Price data loaded! Starting EA...");
      indicatorsReady = true;
   }
   
   // Calculate indicators manually
   double currentEMA = CalculateEMA(close, EMA_Period, 0);
   double prevEMA = CalculateEMA(close, EMA_Period, 1);
   
   double currentRSI = CalculateRSI(close, RSI_Period, 0);
   
   double currentMACD = CalculateMACD(close, MACD_Fast, MACD_Slow, 0);
   double currentSignal = CalculateSignalLine(close, MACD_Fast, MACD_Slow, MACD_Signal, 0);
   
   double currentATR = CalculateATR(high, low, close, ATR_Period, 0);
   
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   Print("EMA: ", NormalizeDouble(currentEMA, Digits()), " RSI: ", NormalizeDouble(currentRSI, 2), 
         " MACD: ", NormalizeDouble(currentMACD, 5), " Signal: ", NormalizeDouble(currentSignal, 5),
         " Ask: ", ask, " Bid: ", bid);
   
   // Check drawdown
   if(!CheckDrawdown())
   {
      Print("Maximum drawdown reached. No new trades allowed.");
      return;
   }
   
   // Check existing trades count
   int openTrades = CountOpenTrades();
   if(openTrades >= MaxTrades)
   {
      return;
   }
   
   // BUY Signal
   if(ask > currentEMA &&                       // Price above EMA (uptrend)
      currentEMA > prevEMA &&                   // EMA trending up
      currentRSI < RSI_Overbought &&            // RSI not overbought
      currentRSI > 40 &&                        // RSI confirmation
      currentMACD > currentSignal &&            // MACD positive
      currentMACD > 0)                          // MACD above zero
   {
      if(!HasOpenBuy())
      {
         Print("BUY signal triggered!");
         double tp, sl;
         
         if(UseATR)
         {
            sl = NormalizeDouble(ask - currentATR, Digits());
            tp = NormalizeDouble(ask + (currentATR * 2), Digits());
         }
         else
         {
            double pipSize = GetPipSize();
            sl = NormalizeDouble(ask - (pipSize * StopLossPips), Digits());
            tp = NormalizeDouble(ask + (pipSize * TakeProfitPips), Digits());
         }
         
         OpenTrade(ORDER_TYPE_BUY, LotSize, ask, sl, tp, "EMA+RSI+MACD BUY Signal");
      }
   }
   
   // SELL Signal
   if(bid < currentEMA &&                       // Price below EMA (downtrend)
      currentEMA < prevEMA &&                   // EMA trending down
      currentRSI > RSI_Oversold &&              // RSI not oversold
      currentRSI < 60 &&                        // RSI confirmation
      currentMACD < currentSignal &&            // MACD negative
      currentMACD < 0)                          // MACD below zero
   {
      if(!HasOpenSell())
      {
         Print("SELL signal triggered!");
         double tp, sl;
         
         if(UseATR)
         {
            sl = NormalizeDouble(bid + currentATR, Digits());
            tp = NormalizeDouble(bid - (currentATR * 2), Digits());
         }
         else
         {
            double pipSize = GetPipSize();
            sl = NormalizeDouble(bid + (pipSize * StopLossPips), Digits());
            tp = NormalizeDouble(bid - (pipSize * TakeProfitPips), Digits());
         }
         
         OpenTrade(ORDER_TYPE_SELL, LotSize, bid, sl, tp, "EMA+RSI+MACD SELL Signal");
      }
   }
   
   // Check for exit signals
   CheckExitSignals(currentMACD, currentSignal);
}

//+------------------------------------------------------------------+
//| Calculate EMA manually                                            |
//+------------------------------------------------------------------+
double CalculateEMA(double &data[], int period, int shift)
{
   if(ArraySize(data) < period + shift) return 0;
   
   double ema = 0;
   double multiplier = 2.0 / (period + 1);
   
   // Calculate SMA first
   double sum = 0;
   for(int i = shift; i < shift + period; i++)
   {
      sum += data[i];
   }
   ema = sum / period;
   
   // Calculate EMA
   for(int i = shift - 1; i >= 0; i--)
   {
      ema = data[i] * multiplier + ema * (1 - multiplier);
   }
   
   return ema;
}

//+------------------------------------------------------------------+
//| Calculate RSI manually                                            |
//+------------------------------------------------------------------+
double CalculateRSI(double &data[], int period, int shift)
{
   if(ArraySize(data) < period + shift + 1) return 50;
   
   double gains = 0, losses = 0;
   
   for(int i = shift; i < shift + period; i++)
   {
      double diff = data[i] - data[i + 1];
      if(diff > 0)
         gains += diff;
      else
         losses += MathAbs(diff);
   }
   
   double avgGain = gains / period;
   double avgLoss = losses / period;
   
   if(avgLoss == 0)
      return 100;
   
   double rs = avgGain / avgLoss;
   double rsi = 100 - (100 / (1 + rs));
   
   return rsi;
}

//+------------------------------------------------------------------+
//| Calculate MACD manually                                           |
//+------------------------------------------------------------------+
double CalculateMACD(double &data[], int fast, int slow, int shift)
{
   double fastEMA = CalculateEMA(data, fast, shift);
   double slowEMA = CalculateEMA(data, slow, shift);
   
   return fastEMA - slowEMA;
}

//+------------------------------------------------------------------+
//| Calculate Signal Line manually                                    |
//+------------------------------------------------------------------+
double CalculateSignalLine(double &data[], int fast, int slow, int signal, int shift)
{
   if(ArraySize(data) < slow + signal + shift) return 0;
   
   // Create MACD array
   double macdArray[100];
   for(int i = 0; i < 100; i++)
   {
      if(i + shift < ArraySize(data))
         macdArray[i] = CalculateMACD(data, fast, slow, i + shift);
   }
   
   // Calculate EMA of MACD
   double signalLine = CalculateEMA(macdArray, signal, shift);
   
   return signalLine;
}

//+------------------------------------------------------------------+
//| Calculate ATR manually                                            |
//+------------------------------------------------------------------+
double CalculateATR(double &high[], double &low[], double &close[], int period, int shift)
{
   if(ArraySize(high) < period + shift || ArraySize(low) < period + shift || 
      ArraySize(close) < period + shift + 1) return 0;
   
   double sum = 0;
   
   for(int i = shift; i < shift + period; i++)
   {
      double tr = high[i] - low[i];
      double tr2 = MathAbs(high[i] - close[i + 1]);
      double tr3 = MathAbs(low[i] - close[i + 1]);
      
      double trueRange = MathMax(tr, MathMax(tr2, tr3));
      sum += trueRange;
   }
   
   return sum / period;
}

//+------------------------------------------------------------------+
//| Open a trade with proper validation                              |
//+------------------------------------------------------------------+
void OpenTrade(ENUM_ORDER_TYPE orderType, double volume, double price, 
               double sl, double tp, string comment)
{
   // Validate parameters
   if(volume <= 0)
   {
      Print("Invalid volume: ", volume);
      return;
   }
   
   if(price <= 0)
   {
      Print("Invalid price: ", price);
      return;
   }
   
   if(sl <= 0)
   {
      Print("Invalid stop loss: ", sl);
      return;
   }
   
   if(tp <= 0)
   {
      Print("Invalid take profit: ", tp);
      return;
   }
   
   // Normalize all prices
   price = NormalizeDouble(price, Digits());
   sl = NormalizeDouble(sl, Digits());
   tp = NormalizeDouble(tp, Digits());
   
   // Validate SL and TP for BUY
   if(orderType == ORDER_TYPE_BUY)
   {
      if(sl >= price)
      {
         Print("BUY: Stop loss must be below price. SL: ", sl, " Price: ", price);
         return;
      }
      if(tp <= price)
      {
         Print("BUY: Take profit must be above price. TP: ", tp, " Price: ", price);
         return;
      }
   }
   
   // Validate SL and TP for SELL
   if(orderType == ORDER_TYPE_SELL)
   {
      if(sl <= price)
      {
         Print("SELL: Stop loss must be above price. SL: ", sl, " Price: ", price);
         return;
      }
      if(tp >= price)
      {
         Print("SELL: Take profit must be below price. TP: ", tp, " Price: ", price);
         return;
      }
   }
   
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = volume;
   request.type = orderType;
   request.price = price;
   request.sl = sl;
   request.tp = tp;
   request.deviation = 20;
   request.magic = MagicNumber;
   request.comment = comment;
   
   Print("Sending trade request: Type=", (orderType == ORDER_TYPE_BUY ? "BUY" : "SELL"), 
         " Price=", price, " SL=", sl, " TP=", tp, " Volume=", volume);
   
   if(!OrderSend(request, result))
   {
      Print("OrderSend error: ", GetLastError(), " Retcode: ", result.retcode, " Comment: ", result.comment);
   }
   else
   {
      Print("Trade opened successfully! Order: ", result.order, " at price: ", result.price);
   }
}

//+------------------------------------------------------------------+
//| Close a trade by ticket                                          |
//+------------------------------------------------------------------+
bool CloseTrade(ulong ticket)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.deviation = 20;
   
   if(!PositionSelectByTicket(ticket))
   {
      Print("Position not found: ", ticket);
      return false;
   }
   
   ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   double posVolume = PositionGetDouble(POSITION_VOLUME);
   double closePrice = (posType == POSITION_TYPE_BUY) ? 
                       SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                       SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   closePrice = NormalizeDouble(closePrice, Digits());
   
   if(posType == POSITION_TYPE_BUY)
   {
      request.type = ORDER_TYPE_SELL;
   }
   else
   {
      request.type = ORDER_TYPE_BUY;
   }
   
   request.volume = posVolume;
   request.price = closePrice;
   request.position = ticket;
   
   if(!OrderSend(request, result))
   {
      Print("OrderSend close error: ", GetLastError());
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check for exit signals (MACD reversal)                           |
//+------------------------------------------------------------------+
void CheckExitSignals(double currentMACD, double currentSignal)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      
      if(ticket == 0)
         continue;
      
      if(!PositionSelectByTicket(ticket))
         continue;
      
      if(PositionGetString(POSITION_SYMBOL) != _Symbol || 
         PositionGetInteger(POSITION_MAGIC) != MagicNumber)
      {
         continue;
      }
      
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      
      // Exit BUY on MACD reversal
      if(type == POSITION_TYPE_BUY && currentMACD < currentSignal)
      {
         CloseTrade(ticket);
         Print("BUY position closed - MACD reversal");
      }
      
      // Exit SELL on MACD reversal
      if(type == POSITION_TYPE_SELL && currentMACD > currentSignal)
      {
         CloseTrade(ticket);
         Print("SELL position closed - MACD reversal");
      }
   }
}

//+------------------------------------------------------------------+
//| Count open trades with EA's magic number                         |
//+------------------------------------------------------------------+
int CountOpenTrades()
{
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      
      if(ticket == 0)
         continue;
      
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         {
            count++;
         }
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Check if we have an open BUY position                            |
//+------------------------------------------------------------------+
bool HasOpenBuy()
{
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      
      if(ticket == 0)
         continue;
      
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         {
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Check if we have an open SELL position                           |
//+------------------------------------------------------------------+
bool HasOpenSell()
{
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      
      if(ticket == 0)
         continue;
      
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
         {
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Check drawdown limit                                             |
//+------------------------------------------------------------------+
bool CheckDrawdown()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   if(balance == 0) return true;
   
   double drawdown = ((balance - equity) / balance) * 100;
   
   if(drawdown > MaxDrawdown)
   {
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Get pip size for the symbol                                      |
//+------------------------------------------------------------------+
double GetPipSize()
{
   return SymbolInfoDouble(_Symbol, SYMBOL_POINT);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("EA deinitialized");
}
