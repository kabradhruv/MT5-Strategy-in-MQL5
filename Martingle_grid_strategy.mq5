#include <Trade\Trade.mqh>
#include <Indicators\Trend.mqh>

// stop after 2 sl
// lots not working after 0.04
// skipping trades

#property copyright "YourName"
#property link      "https://yourwebsite.com"
#property version   "1.00"
#property strict

CTrade trade;
CPositionInfo PositionInfo;

// Input Parameters
input double GridSize = 3.0;              // Distance between grid levels
input double LotSize = 0.01;              // Lot size for orders
input double Slippage = 0.030;            // Allowed price slippage
input int MagicNumber = 123456;           // Unique identifier for strategy orders
input string Symbol = "XAUUSD";           // Trading symbol
input int CheckInterval = 1;              // Check price every second (in seconds)
input ulong Slippage_for_buy = 20; // Adjust based on broker and volatility
input int multiplier = 2;
   
// Global Variables
double LastTouchedGrid = 0;               // Last touched grid level
datetime LastCheckTime = 0;               // Time of the last grid check
double increasedLotSize = LotSize ;
double SL = NULL;
double TP = NULL;

//+------------------------------------------------------------------+
//| Expert Initialization Function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("Grid Strategy Expert Advisor Initialized.");
   LastTouchedGrid = 0;  // Reset grid level tracker
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert Deinitialization Function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("Grid Strategy Expert Advisor Deinitialized.");
}

//---




void OnTick()
{
   // Get current price
   double CurrentPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double RoundedGrid = MathRound(CurrentPrice);
   
   // Set slippage globally
   trade.SetDeviationInPoints(Slippage_for_buy);

   // Check if the price touches a new grid level
   if (IsValidGridLevel(CurrentPrice) == true && RoundedGrid != LastTouchedGrid)
   {
   
      if(SL==RoundedGrid){
            increasedLotSize *= multiplier; // Double the lot size
            Print("Stop Loss hit. New LotSize: ", increasedLotSize);
            }
      if(TP==RoundedGrid){
            increasedLotSize = LotSize; // Reset to default
            Print("Take Profit hit. LotSize reset to default: ", increasedLotSize);
            }
            
      PrintFormat("Old Grid Level: %.5f | New Grid Level: %.5f", LastTouchedGrid, RoundedGrid);

         if (RoundedGrid > LastTouchedGrid)
         {
            // Buy trade
            SL = RoundedGrid - GridSize;
            TP = RoundedGrid + GridSize;
            PlaceOrder(true, CurrentPrice, SL, TP);
         }
         else if (RoundedGrid < LastTouchedGrid)
         {
            // Sell trade
            SL = RoundedGrid + GridSize;
            TP = RoundedGrid - GridSize;
            PlaceOrder(false, CurrentPrice, SL, TP);
         }
         LastTouchedGrid = RoundedGrid;

   }
}




bool PlaceOrder(bool isBuy, double price, double sl, double tp)
{
    int retries = 3;  // Retry up to 3 times
    while (retries > 0)
    {
        bool result;
        if (isBuy)
            result = trade.Buy(increasedLotSize, _Symbol, price, sl, tp, " Buy Order Retry - " + IntegerToString(retries));
        else
            result = trade.Sell(increasedLotSize, _Symbol, price, sl, tp, "Sell Order Retry - " + IntegerToString(retries));

        if (result) return true;

        Print("Requote detected. Retrying...");
        Sleep(1000);  // Wait for 1 second before retrying
        retries--;
    }
    Print("Failed to place order after retries as instant");
    
      MqlTradeRequest request;
      MqlTradeResult result;
      
      // Prepare the request
      ZeroMemory(request);  // Clear the structure
      ZeroMemory(result);   // Clear the result
    
    if (isBuy){

         
         // Fill the request structure for a BUY order
         request.action = TRADE_ACTION_DEAL;         // Market execution
         request.symbol = _Symbol;                   // Current symbol
         request.volume = increasedLotSize;                   // Lot size
         request.type = ORDER_TYPE_BUY;              // Market Buy order
         request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);                   // Market price for Buy
         request.sl = sl;                      // Stop Loss price
         request.tp = tp;                    // Take Profit price
         request.deviation = Slippage_for_buy;               // Slippage in points
         request.comment = "Market order buy";                  // Order comment
         
         // Send the trade request
         if (OrderSend(request, result))
         {
            Print("Market Buy Order Successful. Ticket: ", result.order);
            return true;
         }
         else
         {
            Print("Market Buy Order Failed. Error: ", GetLastError());
            return false;
         }
     }

    else{
         // Fill the request structure for a BUY order
         request.action = TRADE_ACTION_DEAL;         // Market execution
         request.symbol = _Symbol;                   // Current symbol
         request.volume = increasedLotSize;                   // Lot size
         request.type = ORDER_TYPE_SELL;              // Market Buy order
         request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);                   // Market price for Buy
         request.sl = sl;                      // Stop Loss price
         request.tp = tp;                    // Take Profit price
         request.deviation = Slippage_for_buy;               // Slippage in points
         request.comment = "Market order sell";                  // Order comment
         
         // Send the trade request
         if (OrderSend(request, result))
         {
            Print("Market Sell Order Successful. Ticket: ", result.order);
            return true;
         }
         else
         {
            Print("Market Sell Order Failed. Error: ", GetLastError());
            return false;
         }
     }
    
    return false;
    }

bool IsValidGridLevel(double price)
{
   double RoundedPrice = MathRound(price);
   bool is_valid_grid = MathMod(RoundedPrice,GridSize) == 0;
   return is_valid_grid && (MathAbs(price - RoundedPrice) <= Slippage);
}
