//+------------------------------------------------------------------+
//|                                              MoneyManagement.mq4 |
//|                                      Copyright 2014, Junjie Tang |
//|                                            razorsniper@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

#property indicator_chart_window

//---- input parameters
extern int    FontSize = 11;
extern double MaxRiskPercentage = 0.01;
int    nDigits;
int    nTimes;
double LeastPipPoint;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
//---- indicators
   if(StringFind(Symbol(), "JPY", 0) >= 0 || StringFind(Symbol(), "XAU", 0) >= 0) {
      nDigits = 3;
      LeastPipPoint = 0.01;
      nTimes = 100;
   }
   else {
      nDigits = 5;
      LeastPipPoint = 0.0001;
      nTimes = 10000;
   }
//----
   return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
{
//----
   ObjectDelete("MaxStopLossPips");
   ObjectDelete("MinCapitalSize");
   ObjectDelete("MaxLotSize");
   ObjectDelete("SwingRange");
//----
   return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
{
   RefreshRates();   // automatically refresh the chart
   WindowRedraw();   // now redraw all
//----
   double SwingRange_MN1 = 0.0, SwingRange_W1 = 0.0, SwingRange_D1 = 0.0, SwingRange_H4 = 0.0, SwingRange_H1 = 0.0, MarginRequired = 0.0;
   double SwingRange_M30 = 0.0, SwingRange_M15 = 0.0, SwingRange_M5 = 0.0, SwingRange_M1 = 0.0, MaxStopLossPips = 0.0, SwingRange = 0.0;
   double MinCapitalSize = 0.0, MaxRiskLots = 0.0, AvailableLots = 0.0, TotalOpenOrderLots = 0.0, TotalOrderRiskLots = 0.0, TotalOrderProfit = 0.0;
   string Text_MaxStopLossPips = "", Text_MinCapitalSize = "", Text_SwingRange = "", Text_MaxLotSize = "";
   
   // Total open order lots without risk
   for(int i = 0; i < OrdersTotal(); i++) {
      if(!OrderSelect(i, SELECT_BY_POS)) continue;
      TotalOrderProfit += OrderProfit();
      TotalOpenOrderLots += OrderLots();
      if(OrderStopLoss() != 0) {
         if(OrderType() == OP_BUY && OrderStopLoss() - OrderOpenPrice() >= 0) continue;
         if(OrderType() == OP_SELL && OrderOpenPrice() - OrderStopLoss() >= 0) continue;
      }
      TotalOrderRiskLots += OrderLots();
   }
   
   // Calculate average price swing range
   for(i = 1; i <= 240; i++) {
      SwingRange_MN1 += (iHigh(NULL, PERIOD_MN1, i) - iLow(NULL, PERIOD_MN1, i)) / Point / 10;
      SwingRange_W1 += (iHigh(NULL, PERIOD_W1, i) - iLow(NULL, PERIOD_W1, i)) / Point / 10;
      SwingRange_D1 += (iHigh(NULL, PERIOD_D1, i) - iLow(NULL, PERIOD_D1, i)) / Point / 10;
      SwingRange_H4 += (iHigh(NULL, PERIOD_H4, i) - iLow(NULL, PERIOD_H4, i)) / Point / 10;
      SwingRange_H1 += (iHigh(NULL, PERIOD_H1, i) - iLow(NULL, PERIOD_H1, i)) / Point / 10;
      SwingRange_M30 += (iHigh(NULL, PERIOD_M30, i) - iLow(NULL, PERIOD_M30, i)) / Point / 10;
      SwingRange_M15 += (iHigh(NULL, PERIOD_M15, i) - iLow(NULL, PERIOD_M15, i)) / Point / 10;
      SwingRange_M5 += (iHigh(NULL, PERIOD_M5, i) - iLow(NULL, PERIOD_M5, i)) / Point / 10;
      SwingRange_M1 += (iHigh(NULL, PERIOD_M1, i) - iLow(NULL, PERIOD_M1, i)) / Point / 10;
      
      if(i == 240) {
         SwingRange_MN1 /= i;
         SwingRange_W1 /= i;
         SwingRange_D1 /= i;
         SwingRange_H4 /= i;
         SwingRange_H1 /= i;
         SwingRange_M30 /= i;
         SwingRange_M15 /= i;
         SwingRange_M5 /= i;
         SwingRange_M1 /= i;
      }
   }
   
   // Calculate maximum stop loss pips
   MaxStopLossPips = SwingRange_D1;
   
   // Calulate minimum capital size required for 1 mini lot (0.01)
   MinCapitalSize = MaxStopLossPips / MaxRiskPercentage / 10;
   
   // Calculate margin required for 1 mini lot (0.01)
   MarginRequired = MarketInfo(Symbol(),MODE_MARGINREQUIRED) * 0.01;
   
   // Calculate maximum risk lots
   MaxRiskLots = MathFloor(AccountBalance() / (MinCapitalSize + MarginRequired)) * 0.01;
   if (MaxRiskLots==0.0) MaxRiskLots=0.01;
   
   // Calculate available lots
   AvailableLots = MaxRiskLots - TotalOrderRiskLots;
   
   // Display maximum stop loss in pips
   ObjectCreate("MaxStopLossPips", OBJ_LABEL, 0,0,0,0,0,0,0);
   ObjectSet("MaxStopLossPips", OBJPROP_CORNER, 0);
   ObjectSet("MaxStopLossPips", OBJPROP_XDISTANCE, 0);
   ObjectSet("MaxStopLossPips", OBJPROP_YDISTANCE, 10);
   if (TotalOpenOrderLots > 0) {
      Text_MaxStopLossPips = StringConcatenate("S/L: ", DoubleToStr(MaxStopLossPips, 1));
   }
   else {
      Text_MaxStopLossPips = StringConcatenate("S/L: ", DoubleToStr(MaxStopLossPips, 1));
   }
   ObjectSetText("MaxStopLossPips", "", FontSize, "Consolas", DeepSkyBlue);
   ObjectSetText("MaxStopLossPips", Text_MaxStopLossPips);
   
   // Display minimum capital required for 1 mini lot (0.01)
   ObjectCreate("MinCapitalSize", OBJ_LABEL, 0,0,0,0,0,0,0);
   ObjectSet("MinCapitalSize", OBJPROP_CORNER, 1);
   ObjectSet("MinCapitalSize", OBJPROP_XDISTANCE, 5);
   ObjectSet("MinCapitalSize", OBJPROP_YDISTANCE, 10);
   Text_MinCapitalSize = StringConcatenate("M/C: $",DoubleToStr(MinCapitalSize, 2));
   ObjectSetText("MinCapitalSize", "", FontSize, "Consolas", Orange);
   ObjectSetText("MinCapitalSize", Text_MinCapitalSize);
   
   // Display weekly average swing range in pips
   ObjectCreate("SwingRange", OBJ_LABEL, 0,0,0,0,0,0,0);
   ObjectSet("SwingRange", OBJPROP_CORNER, 2);
   ObjectSet("SwingRange", OBJPROP_XDISTANCE, 0);
   ObjectSet("SwingRange", OBJPROP_YDISTANCE, 5);
   Text_SwingRange = StringConcatenate("S/R: ",DoubleToStr(SwingRange_W1, 1));
   ObjectSetText("SwingRange", "", FontSize, "Consolas", DarkKhaki);
   ObjectSetText("SwingRange", Text_SwingRange);
   
   // Display maximume lot size available
   if (AvailableLots >= 0) {
      ObjectCreate("MaxLotSize", OBJ_LABEL, 0,0,0,0,0,0,0);
      ObjectSet("MaxLotSize", OBJPROP_CORNER, 3);
      ObjectSet("MaxLotSize", OBJPROP_XDISTANCE, 5);
      ObjectSet("MaxLotSize", OBJPROP_YDISTANCE, 5);
      Text_MaxLotSize = DoubleToStr(AvailableLots, 2);
      if (TotalOpenOrderLots < MaxRiskLots) {
         ObjectSetText("MaxLotSize", "", FontSize, "Consolas", Gold);
      }
      else {
         Text_MaxLotSize = DoubleToStr(TotalOpenOrderLots, 2);
         ObjectSetText("MaxLotSize", "", FontSize, "Consolas", Lavender);
      }
      ObjectSetText("MaxLotSize", Text_MaxLotSize);
   }
   
   RefreshRates();   // automatically refresh the chart
   WindowRedraw();   // now redraw all
   
//----
   return(0);
}
//+------------------------------------------------------------------+