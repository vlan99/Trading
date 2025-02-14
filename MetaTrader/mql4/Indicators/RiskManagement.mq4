//+------------------------------------------------------------------+
//|                                               RiskManagement.mq4 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window

//---- input parameters
extern double MaxPerRiskPercent=1.5;     // Maximum capital risk percent allowed at any time
extern int    FontSize=10;               // Risk management label text size
extern bool   HighLowOn=true;            // Display last High/Low price line

bool firstTime = true;
datetime lastTime = 0;
int nTimes = 0;
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
{
//----
   ObjectDelete("MaxLotSize");
   ObjectDelete("MaxStopLoss");
   ObjectDelete("SwingRange");
   ObjectDelete("hl_LastDayHigh");
   ObjectDelete("hl_LastDayLow"); 
   ObjectDelete("hl_TodayOpen");
   ObjectDelete("hl_MovingAverage120");
   ObjectDelete("hl_MovingAverage240");      
   for ( int i = ObjectsTotal() - 1; i >= 0; i-- ) {
      string name = ObjectName( i );
      if ( StringFind( name, "grid_" ) >= 0 ) 
         ObjectDelete( name );
   }
//----
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(void)
{
//--- indicator buffers mapping
   // Calculate base info
   nTimes=(int)MathPow(10,Digits);
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
//--->Added per helpdesk instruction
class CFix { } ExtFix;
//--->end
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
//----
   RefreshRates();   // automatically refresh the chart
   WindowRedraw();   // now redraw the chart
   ObjectsRedraw();  // now redraw all objects on the chart
    
   int i = 0, TotalBarCount = 0;
   double SwingRange_MN1 = 0.0, SwingRange_W1 = 0.0, SwingRange_D1 = 0.0, SwingRange_H4 = 0.0, SwingRange_H1 = 0.0, SwingRange_M30 = 0.0, SwingRange_M15 = 0.0, SwingRange_M5 = 0.0, LastDayHigh = 0.0, LastDayLow = 0.0, TodayOpen = 0.0; 
   double MarginRequired = 0.0, MaxStopLossPips = 0.0, MaxStopLossAmount = 0.0, PipValue = 0.0, MaxSpread = 0.0, MovingAverage120 = 0.0, MovingAverage240 = 0.0, TargetPips=0.0;
   double CapitalMaxRiskAmount = 0.0, MaxRiskLots = 0.0, AvailableLots = 0.0, TotalOpenOrderLots = 0.0, TotalRiskOrderLots = 0.0, TotalRiskOrderProfit = 0.0;
   string Text_MaxStopLoss = "", Text_MaxLotSize = "", Text_SwingRange = "";

   // Total open order lots without risk
   for(i=0; i<OrdersTotal(); i++) 
   {
      if(!OrderSelect(i,SELECT_BY_POS)) continue;
      if (OrderStopLoss()!=0) 
      {
         if(Symbol()==OrderSymbol()) TotalOpenOrderLots+=OrderLots();
         if(OrderType() == OP_BUY && OrderStopLoss() - OrderOpenPrice() >= 0) continue;
         if(OrderType() == OP_SELL && OrderOpenPrice() - OrderStopLoss() >= 0) continue;
      }
      if(Symbol()==OrderSymbol())
      {
         TotalRiskOrderLots+=OrderLots();
         TotalRiskOrderProfit+=OrderProfit();
      }
   }
    
   // Calculate average price swing range
   TotalBarCount = 240;
   for(i=1; i<=TotalBarCount; i++) 
   {
      SwingRange_MN1 += (iHigh(NULL, PERIOD_MN1, i) - iLow(NULL, PERIOD_MN1, i));
      SwingRange_W1 += (iHigh(NULL, PERIOD_W1, i) - iLow(NULL, PERIOD_W1, i));
      SwingRange_D1 += (iHigh(NULL, PERIOD_D1, i) - iLow(NULL, PERIOD_D1, i));
      SwingRange_H4 += (iHigh(NULL, PERIOD_H4, i) - iLow(NULL, PERIOD_H4, i));
      SwingRange_H1 += (iHigh(NULL, PERIOD_H1, i) - iLow(NULL, PERIOD_H1, i));
      SwingRange_M30 += (iHigh(NULL, PERIOD_M30, i) - iLow(NULL, PERIOD_M30, i));
      SwingRange_M15 += (iHigh(NULL, PERIOD_M15, i) - iLow(NULL, PERIOD_M15, i));
      SwingRange_M5 += (iHigh(NULL, PERIOD_M5, i) - iLow(NULL, PERIOD_M5, i));
   }
   SwingRange_MN1 /= TotalBarCount;
   SwingRange_W1 /= TotalBarCount;
   SwingRange_D1 /= TotalBarCount;
   SwingRange_H4 /= TotalBarCount;
   SwingRange_H1 /= TotalBarCount;
   SwingRange_M30 /= TotalBarCount;
   SwingRange_M15 /= TotalBarCount;
   SwingRange_M5 /= TotalBarCount;
   
   // Calculate pip value for 1 micro lot (0.01)
   PipValue=MarketInfo(Symbol(),MODE_TICKVALUE)*0.01;

   // Calculate margin required for 1 micro lot (0.01)
   MarginRequired=MarketInfo(Symbol(),MODE_MARGINREQUIRED)*0.01;

   // Calulate maximum risk capital size
   CapitalMaxRiskAmount=AccountBalance()*(MaxPerRiskPercent/100.0);
   
   // Calculate maximum stop loss in pips
   MaxSpread=MarketInfo(Symbol(),MODE_SPREAD)*Point;
   if(Period() <= PERIOD_M30)
   {
       MaxStopLossPips=(SwingRange_M5+MaxSpread)*nTimes;
       TargetPips=SwingRange_D1*nTimes;
   }
   else
   {
       MaxStopLossPips=(SwingRange_M30+MaxSpread)*nTimes;
       TargetPips=SwingRange_W1*nTimes;
   }

   // Calculate maximum risk lots & max stop loss dollar amount
   MaxRiskLots=MathFloor(CapitalMaxRiskAmount/(MaxStopLossPips*PipValue+MarginRequired))*0.01;
   MaxStopLossAmount=MaxStopLossPips*PipValue*MaxRiskLots*100;

   // Calculate available lots
   AvailableLots=NormalizeDouble(MaxRiskLots-TotalRiskOrderLots,2);
   
   // Draw price boundary line according to period
   if(HighLowOn)
   {
      if(Period()<PERIOD_D1)
      {
         // Draw today open price line 
         TodayOpen=iOpen(Symbol(), PERIOD_D1, 0);
         ObjectCreate("hl_TodayOpen", OBJ_HLINE, 0, Time[0], TodayOpen);
         ObjectSet("hl_TodayOpen", OBJPROP_COLOR, Lavender);
         ObjectSet("hl_TodayOpen", OBJPROP_STYLE, STYLE_DASHDOTDOT);         
         
         /*
         // Draw last day high/low price line
         LastDayHigh =iHigh(Symbol(), PERIOD_D1, 1);
         LastDayLow=iLow(Symbol(), PERIOD_D1, 1);
         ObjectCreate("hl_LastDayHigh", OBJ_HLINE, 0, Time[0], LastDayHigh);
         ObjectCreate("hl_LastDayLow", OBJ_HLINE, 0, Time[0], LastDayLow);
         ObjectSet("hl_LastDayHigh", OBJPROP_COLOR, Lavender);
         ObjectSet("hl_LastDayLow", OBJPROP_COLOR, Lavender);
         ObjectSet("hl_LastDayHigh", OBJPROP_STYLE, STYLE_DASH);
         ObjectSet("hl_LastDayLow", OBJPROP_STYLE, STYLE_DASH);
         
         // Draw hour chart current MA120/MA240 price line
         if(Period()<=PERIOD_M5)
         {
            MovingAverage120=iMA(Symbol(), PERIOD_H1, 120, 0, MODE_SMA, PRICE_CLOSE, 0);
            MovingAverage240=iMA(Symbol(), PERIOD_H1, 240, 0, MODE_SMA, PRICE_CLOSE, 0);
            ObjectCreate("hl_MovingAverage120", OBJ_HLINE, 0, Time[0], MovingAverage120);
            ObjectCreate("hl_MovingAverage240", OBJ_HLINE, 0, Time[0], MovingAverage240);
            ObjectSet("hl_MovingAverage120", OBJPROP_COLOR, DarkKhaki);
            ObjectSet("hl_MovingAverage240", OBJPROP_COLOR, RoyalBlue);
            ObjectSet("hl_MovingAverage120", OBJPROP_STYLE, STYLE_DASH);
            ObjectSet("hl_MovingAverage240", OBJPROP_STYLE, STYLE_DASH);
         }
        */
      }
   }
   
   // Display maximume lot size per trade
   ObjectCreate("MaxLotSize",OBJ_LABEL,0,0,0,0,0,0,0);
   ObjectSet("MaxLotSize",OBJPROP_CORNER,3);
   ObjectSet("MaxLotSize",OBJPROP_XDISTANCE,5);
   ObjectSet("MaxLotSize",OBJPROP_YDISTANCE,45);
   ObjectSetString(0,"MaxLotSize",OBJPROP_FONT,"Consolas");
   ObjectSet("MaxLotSize",OBJPROP_FONTSIZE,FontSize);
   if(AvailableLots > 0)
   {
      if(TotalRiskOrderLots > 0)
         ObjectSet("MaxLotSize",OBJPROP_COLOR,Yellow);
      else
         ObjectSet("MaxLotSize",OBJPROP_COLOR,Gold);
      Text_MaxLotSize=StringConcatenate(">>> ", DoubleToStr(AvailableLots,2), " <<<");
   }
   else
   {  
      ObjectSet("MaxLotSize",OBJPROP_COLOR,Lavender);
      Text_MaxLotSize=StringConcatenate(">>> ", DoubleToStr(TotalRiskOrderLots,2), " <<<");
   }
   ObjectSetText("MaxLotSize",Text_MaxLotSize);
    
   // Display maximum stop loss in pips & dollar amount
   ObjectCreate("MaxStopLoss",OBJ_LABEL,0,0,0,0,0,0,0);
   ObjectSet("MaxStopLoss",OBJPROP_CORNER,3);
   ObjectSet("MaxStopLoss",OBJPROP_XDISTANCE,5);
   ObjectSet("MaxStopLoss",OBJPROP_YDISTANCE,25);
   ObjectSetString(0,"MaxStopLoss",OBJPROP_FONT,"Consolas");
   ObjectSet("MaxStopLoss",OBJPROP_FONTSIZE,FontSize);
   ObjectSet("MaxStopLoss",OBJPROP_COLOR,Lime);
   Text_MaxStopLoss=StringConcatenate(DoubleToStr(MaxStopLossPips,0), " -> $", DoubleToStr(MaxStopLossAmount,2));
   ObjectSetText("MaxStopLoss",Text_MaxStopLoss);
   
   // Display minimum margin required & pip value
   ObjectCreate("SwingRange",OBJ_LABEL,0,0,0,0,0,0,0);
   ObjectSet("SwingRange",OBJPROP_CORNER,3);
   ObjectSet("SwingRange",OBJPROP_XDISTANCE,5);
   ObjectSet("SwingRange",OBJPROP_YDISTANCE,5);
   ObjectSetString(0,"SwingRange",OBJPROP_FONT,"Consolas");
   ObjectSet("SwingRange",OBJPROP_FONTSIZE,FontSize);
   ObjectSet("SwingRange",OBJPROP_COLOR,Magenta);
   Text_SwingRange=StringConcatenate(DoubleToStr(TargetPips,0), " -> $", DoubleToStr(TargetPips*PipValue*MaxRiskLots*100,2));
   ObjectSetText("SwingRange",Text_SwingRange);

   RefreshRates();   // automatically refresh the chart
   WindowRedraw();   // now redraw the chart
   ObjectsRedraw();  // now redraw all objects on the chart
    
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+