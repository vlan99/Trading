//+------------------------------------------------------------------+
//|                                                          Sai.mq4 |
//|                                            Copyright ? 2013, Sai |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013 @ Sai"
#property link      "razor_norip@hotmail.com"
#property indicator_chart_window

//---- input parameters
extern bool   Enable = true;
extern int    FontSize = 11;
int    nDigits;
int    nTimes;
double LeastPipPoint;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
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

   return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
{
   //---- 
   ObjectDelete("MaxStopLossPips");
   ObjectDelete("MaxLotSize");
   ObjectDelete("SwingRange");
   ObjectDelete("DashBoard");
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
   
   if (!Enable) return(0);
    
   //----
   double SwingRange_MN1 = 0.0, SwingRange_W1 = 0.0, SwingRange_D1 = 0.0, SwingRange_H4 = 0.0, SwingRange_H1 = 0.0, MarginRequired = 0.0;
   double SwingRange_M30 = 0.0, SwingRange_M15 = 0.0, SwingRange_M5 = 0.0, SwingRange_M1 = 0.0, MaxStopLossPips = 0.0, SwingRange = 0.0, RiskRewardRatio = 0.0;
   double MaxRiskLots = 0.0, AvailableLots = 0.0, RiskPercentage = 0.0, TotalOpenOrderLots = 0.0, TotalOrderRiskLots = 0.0, TotalOrderProfit = 0.0;
   string Text_MaxStopLossPips = "", Text_SwingRange = "", Text_MaxLotSize = "", Text_DashBoard = "";

   // Total Open Order Lots Without Risk
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

   // Calculate Average Price Swing Range
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
   
   // Calculate Maximum Stop Loss Pips
   MaxStopLossPips = SwingRange_H4;
   
   // Calculate Margin Required to Open 0.01 lot
   MarginRequired = MarketInfo(Symbol(),MODE_MARGINREQUIRED) * 0.01;
   
   // Calculate Maximum Risk Lots
   MaxRiskLots = MathFloor(AccountBalance() / (100 + MarginRequired)) * 0.01;
   if (MaxRiskLots==0.0) MaxRiskLots=0.01;
   
   // Calculate Available Lots
   AvailableLots = MaxRiskLots - TotalOrderRiskLots;
   
   // Calculate Risk Percentage
   RiskPercentage = (TotalOrderProfit / (MaxRiskLots * MaxStopLossPips * 10)) * 100;
   
   // Display Current Level Average Swing Range in Pips
   ObjectCreate("MaxStopLossPips", OBJ_LABEL, 0,0,0,0,0,0,0);
   ObjectSet("MaxStopLossPips", OBJPROP_CORNER, 0);
   ObjectSet("MaxStopLossPips", OBJPROP_XDISTANCE, 0);
   ObjectSet("MaxStopLossPips", OBJPROP_YDISTANCE, 5);
   if (TotalOpenOrderLots > 0) {
      Text_MaxStopLossPips = StringConcatenate("S/L: ", DoubleToStr(MaxStopLossPips, 1), " (", DoubleToStr(TotalOpenOrderLots, 2), ")");
   }
   else {
      Text_MaxStopLossPips = StringConcatenate("S/L: ", DoubleToStr(MaxStopLossPips, 1));
   }
   ObjectSetText("MaxStopLossPips", "", FontSize, "Consolas", DeepSkyBlue);
   ObjectSetText("MaxStopLossPips", Text_MaxStopLossPips);
   
   // Display Dashboard
   ObjectCreate("DashBoard", OBJ_LABEL, 0,0,0,0,0,0,0);
   ObjectSet("DashBoard", OBJPROP_CORNER, 1);
   ObjectSet("DashBoard", OBJPROP_XDISTANCE, 5);
   ObjectSet("DashBoard", OBJPROP_YDISTANCE, 5);
   Text_DashBoard = "Sideways";
   ObjectSetText("DashBoard", "", FontSize, "Consolas", Lavender);
   if (iMA(NULL,0,120,0,MODE_SMA,PRICE_CLOSE,1) > iMA(NULL,0,240,0,MODE_SMA,PRICE_CLOSE,1) && Close[1] > iMA(NULL,0,120,0,MODE_SMA,PRICE_CLOSE,1)) {
      Text_DashBoard = "Uptrends";
      ObjectSetText("DashBoard", "", FontSize, "Consolas", Orange);
   }
   if (iMA(NULL,0,120,0,MODE_SMA,PRICE_CLOSE,1) < iMA(NULL,0,240,0,MODE_SMA,PRICE_CLOSE,1) && Close[1] < iMA(NULL,0,120,0,MODE_SMA,PRICE_CLOSE,1)) {
      Text_DashBoard = "Downtrends";
      ObjectSetText("DashBoard", "", FontSize, "Consolas", Aqua);
   }
   ObjectSetText("DashBoard", Text_DashBoard);
   
   // Display Next Level Average Swing Range in Pips
   ObjectCreate("SwingRange", OBJ_LABEL, 0,0,0,0,0,0,0);
   ObjectSet("SwingRange", OBJPROP_CORNER, 2);
   ObjectSet("SwingRange", OBJPROP_XDISTANCE, 0);
   ObjectSet("SwingRange", OBJPROP_YDISTANCE, 5);
   Text_SwingRange = StringConcatenate("S/R: ", DoubleToStr(SwingRange_D1, 1), " -> ",DoubleToStr(SwingRange_W1, 1));
   ObjectSetText("SwingRange", "", FontSize, "Consolas", DarkKhaki);
   ObjectSetText("SwingRange", Text_SwingRange);
 
   // Lot Risk Management
   ObjectCreate("MaxLotSize", OBJ_LABEL, 0,0,0,0,0,0,0);
   ObjectSet("MaxLotSize", OBJPROP_CORNER, 3);
   ObjectSet("MaxLotSize", OBJPROP_XDISTANCE, 5);
   ObjectSet("MaxLotSize", OBJPROP_YDISTANCE, 5);
   if (AvailableLots > 0) {
      Text_MaxLotSize = DoubleToStr(AvailableLots, 2);
      if (TotalOpenOrderLots < MaxRiskLots) {
         ObjectSetText("MaxLotSize", "", FontSize, "Consolas", Gold);
      }
      else {
         ObjectSetText("MaxLotSize", "", FontSize, "Consolas", DeepSkyBlue);
      }
      ObjectSetText("MaxLotSize", Text_MaxLotSize);
   }
   else {
      Text_MaxLotSize = "Cut loss short, let profit run!";
      ObjectSetText("MaxLotSize", "", FontSize, "Consolas", Yellow);
      ObjectSetText("MaxLotSize", Text_MaxLotSize);
   }
   
   RefreshRates();   // automatically refresh the chart
   WindowRedraw();   // now redraw all
   
   return(0);
}
//+------------------------------------------------------------------+