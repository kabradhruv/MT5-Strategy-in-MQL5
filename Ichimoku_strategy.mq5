#include <Trade\Trade.mqh>
#include <Indicators\Trend.mqh>

CTrade trade;
CiIchimoku ichimoku; // Create an instance of the CIIchimoku class


// User Input
input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;
input ulong InpMagic = 8234;
input double RiskPercent = 2;

// Boolean Conditions
bool FutureCloudGreen = false, FutureCloudRed = false;
bool PriceaboveCloud = false, PricebelowCloud = false;
bool TenkanaboveKijun = false, TenkanbelowKijun = false;
bool ChikouaboveCloud = false, ChikoubelowCloud = false;

int OnInit()
{
   trade.SetExpertMagicNumber(InpMagic);
   ichimoku = new CiIchimoku();
   ichimoku.Create(_Symbol, Timeframe, 9, 26, 52);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
}

void OnTick()
{
   if (!IsNewBar()) return;

   ichimoku.Refresh(-1);

   double SpanAx1 = ichimoku.SenkouSpanA(1);
   double SpanAx2 = ichimoku.SenkouSpanA(2);
   double SpanAx26 = ichimoku.SenkouSpanA(26);
   double SpanAf26 = ichimoku.SenkouSpanA(-26);

   double SpanBx1 = ichimoku.SenkouSpanB(1);
   double SpanBx2 = ichimoku.SenkouSpanB(2);
   double SpanBx26 = ichimoku.SenkouSpanB(26);
   double SpanBf26 = ichimoku.SenkouSpanB(-26);

   double Tenkan = ichimoku.TenkanSen(1);
   double Kijun = ichimoku.KijunSen(1);
   double Chikou = ichimoku.ChinkouSpan(26);

   double Closex1 = iClose(_Symbol, Timeframe, 1);
   double Closex2 = iClose(_Symbol, Timeframe, 2);

   // Checking Conditions
   // Future Cloud is Green or Red
   if (SpanAf26 > SpanBf26) {
      FutureCloudGreen = true;
      FutureCloudRed = false;
   } else if (SpanBf26 > SpanAf26) {
      FutureCloudRed = true;
      FutureCloudGreen = false;
   }

   // Exit Cloud Up OR Exit Cloud Below
   if (PriceaboveCloud == false && (Closex2 < SpanAx2 || Closex2 < SpanBx2) && (Closex1 > SpanAx1 && Closex1 > SpanBx1)) {
      PriceaboveCloud = true;
      PricebelowCloud = false;
   } else if (PricebelowCloud == false && (Closex2 > SpanAx2 || Closex2 > SpanBx2) && (Closex1 < SpanAx1 && Closex1 < SpanBx1)) {
      PricebelowCloud = true;
      PriceaboveCloud = false;
   }

   // Tenkan above Kijun or Tenkan below Kijun
   if (Tenkan > Kijun) {
      TenkanaboveKijun = true;
      TenkanbelowKijun = false;
   } else if (Tenkan < Kijun) {
      TenkanaboveKijun = false;
      TenkanbelowKijun = true;
   }

   // Chikou above or below Cloud 26 bars back
   if (Chikou > SpanAx26 && Chikou > SpanBx26) {
      ChikouaboveCloud = true;
      ChikoubelowCloud = false;
   } else if (Chikou < SpanAx26 && Chikou < SpanBx26) {
      ChikouaboveCloud = false;
      ChikoubelowCloud = true;
   }

   // Close of price is in the Cloud
   if (SpanAx1 > SpanBx1 && Closex1 > SpanBx1 && Closex1 < SpanAx1) {
      PriceaboveCloud = false;
      PricebelowCloud = false;
   } else if (SpanBx1 > SpanAx1 && Closex1 > SpanAx1 && Closex1 < SpanBx1) {
      PriceaboveCloud = false;
      PricebelowCloud = false;
   }

   // Chikou is in the Cloud
   if (SpanAx26 > SpanBx26 && Chikou > SpanBx26 && Chikou < SpanAx26) {
      ChikouaboveCloud = false;
      ChikoubelowCloud = false;
   } else if (SpanBx26 > SpanAx26 && Chikou > SpanAx26 && Chikou < SpanBx26) {
      ChikouaboveCloud = false;
      ChikoubelowCloud = false;
   }

   Comment("In PriceaboveCloud: ", PriceaboveCloud,
           "\nTenkan>Kijun: ", TenkanaboveKijun,
           "\nChikouaboveCloud: ", ChikouaboveCloud,
           "\nFutureCloudGreen: ", FutureCloudGreen,
           "\n\n",
           "\nPricebelowCloud: ", PricebelowCloud,
           "\nTenkan<Kijun: ", TenkanbelowKijun,
           "\nChikoubelowCloud: ", ChikoubelowCloud,
           "\nFutureCloudRed: ", FutureCloudRed);

   // Buy Condition
   if (FutureCloudGreen == true && PriceaboveCloud == true && TenkanaboveKijun == true && ChikouaboveCloud == true) {
      double entry = Closex1;
      double sl = Kijun - 50 *_Point;
      double tp = entry + (entry - sl) * 2;
      double lots = calcLots(entry - sl);

      trade.Buy(lots, _Symbol, entry, sl, tp, "Dhruv here buying try");
      SetAllConditionsToFalse();
   }

   // Sell Condition
   if (FutureCloudRed == true && PricebelowCloud == true && TenkanbelowKijun == true && ChikoubelowCloud == true) {
      double entry = Closex1;
      double sl = Kijun + 50 *_Point;
      double tp = entry - (sl-entry) * 2;
      double lots = calcLots(sl-entry);

      trade.Sell(lots, _Symbol, entry, sl, tp, "Dhruv here selling trying in life ");
      SetAllConditionsToFalse();
   }
}

bool IsNewBar()
{
   static datetime previousTime = 0;
   datetime currentTime = iTime(_Symbol,PERIOD_CURRENT,0);

   if (currentTime != previousTime) {
       previousTime = currentTime;
       return true;
   }
   return false;
}

double calcLots(double slPoints)
{
   double risk = AccountInfoDouble(ACCOUNT_BALANCE) * RiskPercent / 100;
   double ticksize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickvalue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double lotstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   double moneyPerLotstep = slPoints / ticksize * tickvalue * lotstep;
   double lots = MathFloor(risk / moneyPerLotstep) * lotstep;

   double minvolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double maxvolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);

   if (maxvolume != 0) lots = MathMin(lots, maxvolume);
   if (minvolume != 0) lots = MathMax(lots, minvolume);

   lots = NormalizeDouble(lots, 2);
   return 0.01;
}

void SetAllConditionsToFalse()
{
   FutureCloudGreen = false;
   FutureCloudRed = false;
   PriceaboveCloud = false;
   PricebelowCloud = false;
   TenkanaboveKijun = false;
   TenkanbelowKijun = false;
   ChikouaboveCloud = false;
   ChikoubelowCloud = false;
}