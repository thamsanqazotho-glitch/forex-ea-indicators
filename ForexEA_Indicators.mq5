//+------------------------------------------------------------------+
//|                        Forex EA - Multi Indicator                |
//|                    EMA, RSI, and MACD Combination                |
//|                                                                  |
//| Entry Logic:                                                    |
//| BUY:  EMA trend UP + RSI < 70 (not overbought) + MACD positive  |
//| SELL: EMA trend DOWN + RSI > 30 (not oversold) + MACD negative  |
//|                                                                  |
//| Exit Logic:                                                     |
//| Take Profit: Fixed pip target or MACD reversal                  |
//| Stop Loss: ATR-based or fixed pips                              |
//+------------------------------------------------------------------+

#property copyright "Copyright 2024"
#property link      "https://github.com/thamsanqazotho-glitch/forex-ea-indicators"
#property version   "1.00"
#property strict

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
int emaHandle, rsiHandle, macdHandle, atrHandle;
double emaBuffer[], rsiBuffer[], macdBuffer[], macdSignalBuffer[], macdHistogram[];
double atrBuffer[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Create indicator handles
   emaHandle = iMA(_Symbol, _Period, EMA_Period, 0, MODE_EMA, PRICE_CLOSE);
   rsiHandle = iRSI(_Symbol, _Period, RSI_Period, PRICE_CLOSE);
   macdHandle = iMACD(_Symbol, _Period, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE);
   atrHandle = iATR(_Symbol, _Period, ATR_Period);
   
   // Check if handles are valid
   if(emaHandle == INVALID_HANDLE || rsiHandle == INVALID_HANDLE || 
      macdHandle == INVALID_HANDLE || atrHandle == INVALID_HANDLE)
   {
      Alert("Failed to create indicator handles");
      return INIT_FAILED;
   }
   
   // Set array indices
   ArraySetAsSeries(emaBuffer, true);
   ArraySetAsSeries(rsiBuffer, true);
   ArraySetAsSeries(macdBuffer, true);
   ArraySetAsSeries(macdSignalBuffer, true);
   ArraySetAsSeries(macdHistogram, true);
   ArraySetAsSeries(atrBuffer, true);
   
   Print("EA initialized successfully on ", _Symbol, " ", _Period);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check if we have enough bars
   if(Bars(_Symbol, _Period) < 50)
   {
      Print("Not enough bars loaded");
      return;
   }
   
   // Copy indicator data
   if(CopyBuffer(emaHandle, 0, 0, 3, emaBuffer) < 0 ||
      CopyBuffer(rsiHandle, 0, 0, 3, rsiBuffer) < 0 ||
      CopyBuffer(macdHandle, 0, 0, 3, macdBuffer) < 0 ||
      CopyBuffer(macdHandle, 1, 0, 3, macdSignalBuffer) < 0 ||
      CopyBuffer(macdHandle, 2, 0, 3, macdHistogram) < 0 ||
      CopyBuffer(atrHandle, 0, 0, 3, atrBuffer) < 0)
   {
      Print("Error copying indicator buffers");
      return;
   }
   
   // Get current indicator values
   double currentEMA = emaBuffer[0];
   double prevEMA = emaBuffer[1];
   double currentRSI = rsiBuffer[0];
   double currentMACD = macdBuffer[0];
   double currentSignal = macdSignalBuffer[0];
   double currentATR = atrBuffer[0];
   
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
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
   if(currentPrice > currentEMA &&                    // Price above EMA (uptrend)
      currentEMA > prevEMA &&                         // EMA trending up
      currentRSI < RSI_Overbought &&                  // RSI not overbought
      currentRSI > 40 &&                              // RSI confirmation
      currentMACD > currentSignal &&                  // MACD positive
      currentMACD > 0)                                // MACD above zero
   {
      if(!HasOpenBuy())
      {
         double tp, sl;
         
         if(UseATR)
         {
            tp = ask + (currentATR * 2);
            sl = ask - currentATR;
         }
         else
         {
            tp = ask + (GetPipSize() * TakeProfitPips);
            sl = ask - (GetPipSize() * StopLossPips);
         }
         
         OpenTrade(ORDER_TYPE_BUY, LotSize, ask, sl, tp, "EMA+RSI+MACD BUY Signal");
      }
   }
   
   // SELL Signal
   if(currentPrice < currentEMA &&                    // Price below EMA (downtrend)
      currentEMA < prevEMA &&                         // EMA trending down
      currentRSI > RSI_Oversold &&                    // RSI not oversold
      currentRSI < 60 &&                              // RSI confirmation
      currentMACD < currentSignal &&                  // MACD negative
      currentMACD < 0)                                // MACD below zero
   {
      if(!HasOpenSell())
      {
         double tp, sl;
         
         if(UseATR)
         {
            tp = bid - (currentATR * 2);
            sl = bid + currentATR;
         }
         else
         {
            tp = bid - (GetPipSize() * TakeProfitPips);
            sl = bid + (GetPipSize() * StopLossPips);
         }
         
         OpenTrade(ORDER_TYPE_SELL, LotSize, bid, sl, tp, "EMA+RSI+MACD SELL Signal");
      }
   }
   
   // Check for exit signals
   CheckExitSignals();
}

//+------------------------------------------------------------------+
//| Open a trade                                                     |
//+------------------------------------------------------------------+
void OpenTrade(ENUM_ORDER_TYPE orderType, double volume, double price, 
               double sl, double tp, string comment)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = volume;
   request.type = orderType;
   request.price = price;
   request.sl = sl;
   request.tp = tp;
   request.deviation = 10;
   request.magic = MagicNumber;
   request.comment = comment;
   
   if(!OrderSend(request, result))
   {
      Print("OrderSend error: ", GetLastError());
   }
   else
   {
      Print("Trade opened: ", result.order, " at price ", result.price);
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
   request.type = ORDER_TYPE_SELL;
   request.position = ticket;
   request.deviation = 10;
   
   PositionSelectByTicket(ticket);
   
   if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
   {
      request.type = ORDER_TYPE_SELL;
      request.volume = PositionGetDouble(POSITION_VOLUME);
      request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   }
   else
   {
      request.type = ORDER_TYPE_BUY;
      request.volume = PositionGetDouble(POSITION_VOLUME);
      request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   }
   
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
void CheckExitSignals()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionSelectByIndex(i))
      {
         if(PositionGetString(POSITION_SYMBOL) != _Symbol || 
            PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         {
            continue;
         }
         
         ulong ticket = PositionGetTicket(i);
         ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         
         // Copy MACD data
         double macdBuffer[], macdSignalBuffer[];
         ArraySetAsSeries(macdBuffer, true);
         ArraySetAsSeries(macdSignalBuffer, true);
         
         CopyBuffer(macdHandle, 0, 0, 3, macdBuffer);
         CopyBuffer(macdHandle, 1, 0, 3, macdSignalBuffer);
         
         // Exit BUY on MACD reversal
         if(type == POSITION_TYPE_BUY && macdBuffer[0] < macdSignalBuffer[0])
         {
            CloseTrade(ticket);
            Print("BUY position closed - MACD reversal");
         }
         
         // Exit SELL on MACD reversal
         if(type == POSITION_TYPE_SELL && macdBuffer[0] > macdSignalBuffer[0])
         {
            CloseTrade(ticket);
            Print("SELL position closed - MACD reversal");
         }
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
      if(PositionSelectByIndex(i))
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
      if(PositionSelectByIndex(i))
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
      if(PositionSelectByIndex(i))
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
   // Release indicator handles
   IndicatorRelease(emaHandle);
   IndicatorRelease(rsiHandle);
   IndicatorRelease(macdHandle);
   IndicatorRelease(atrHandle);
   
   Print("EA deinitalized");
}
