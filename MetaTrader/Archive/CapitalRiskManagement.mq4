//+------------------------------------------------------------------+
//|                                        CapitalRiskManagement.mq4 |
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
extern double MaxCapitalPercent=15.0;    // Maximum capital percent allowed to be used
extern int    FontSize=10;               // Risk management label text size
extern int    HGrid_Weeks=2;             // Period over which to calc High/Low of gird (in weeks)
extern int    HGrid_Pips=1000;           // Size of grid in Pips (100.0)
extern color  HLine=DarkKhaki;           // Color of grid
extern color  HLine2=DarkKhaki;          // Every 100 pips, change grid color to this.
extern bool   EnableGrid=true;           // Grid On/Off


// Recommends settings:
// 1 minute - HGrid_Pips=10, TimeGrid = 10
// 5, 15 minutes - HGrid_Pips=20, TimeGrid= PERIOD_H1 (60)
// 30, 60 minutes - HGrid_Pips=20, TimeGrid = PERIOD_H4 (240) or 2 hours (120)
// 4 hour - HGrid_Pips=50, TimeGrid = PERIOD_D1 (1440) or 12 hours (720)
// 1 day - HGrid_Pips=50, TimeGrid = PERIOD_W1 (10800).

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
   ObjectDelete("MarginRequired");
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
   if (EnableGrid) DrawGrid(); // Round number grid
//----
   RefreshRates();   // automatically refresh the chart
   WindowRedraw();   // now redraw all
    
   int i = 0, TotalBarCount = 0;
   double SwingRange_W1 = 0.0, SwingRange_D1 = 0.0, SwingRange_H4 = 0.0, SwingRange_H1 = 0.0, MarginRequired = 0.0, MaxStopLossPips = 0.0, MaxStopLossAmount = 0.0, PipValue = 0.0, MaxSpread = 0.0;
   double CapitalMaxRiskAmount = 0.0, MaxRiskLots = 0.0, AvailableLots = 0.0, TotalOpenOrderLots = 0.0, TotalRiskOrderLots = 0.0, TotalRiskOrderProfit = 0.0;
   string Text_MaxStopLoss = "", Text_SwingRange = "", Text_MaxLotSize= "", Text_MarginRequired= "";

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
      SwingRange_W1 += (iHigh(NULL, PERIOD_W1, i) - iLow(NULL, PERIOD_W1, i));
      SwingRange_D1 += (iHigh(NULL, PERIOD_D1, i) - iLow(NULL, PERIOD_D1, i));
      SwingRange_H4 += (iHigh(NULL, PERIOD_H4, i) - iLow(NULL, PERIOD_H4, i));
      SwingRange_H1 += (iHigh(NULL, PERIOD_H1, i) - iLow(NULL, PERIOD_H1, i));
   }
   SwingRange_W1 /= TotalBarCount;
   SwingRange_D1 /= TotalBarCount;
   SwingRange_H4 /= TotalBarCount;
   SwingRange_H1 /= TotalBarCount;
    
   // Calculate pip value for 1 micro lot (0.01)
   PipValue=MarketInfo(Symbol(),MODE_TICKVALUE)*0.01;

   // Calculate margin required for 1 micro lot (0.01)
   MarginRequired=MarketInfo(Symbol(),MODE_MARGINREQUIRED)*0.01;

   // Calulate maximum risk capital size
   CapitalMaxRiskAmount=AccountBalance()*(MaxPerRiskPercent/100.0);
   
   // Calculate maximum stop loss in pips
   MaxSpread=MarketInfo(Symbol(),MODE_SPREAD)*Point*1.5;
   if(Period() < PERIOD_D1)
      MaxStopLossPips=MathCeil((SwingRange_H1+MaxSpread)*nTimes);
   else
      MaxStopLossPips=MathCeil((SwingRange_H4+MaxSpread)*nTimes);

   // Calculate maximum risk lots & max stop loss dollar amount
   MaxRiskLots=MathFloor(CapitalMaxRiskAmount/(MaxStopLossPips*PipValue+MarginRequired))*0.01;
   MaxStopLossAmount=MaxStopLossPips*PipValue*MaxRiskLots*100;

   // Calculate available lots
   AvailableLots=NormalizeDouble(MaxRiskLots-TotalRiskOrderLots,2);
   
   // Display maximume lot size per trade
   ObjectCreate("MaxLotSize",OBJ_LABEL,0,0,0,0,0,0,0);
   ObjectSet("MaxLotSize",OBJPROP_CORNER,3);
   ObjectSet("MaxLotSize",OBJPROP_XDISTANCE,5);
   ObjectSet("MaxLotSize",OBJPROP_YDISTANCE,65);
   ObjectSetString(0,"MaxLotSize",OBJPROP_FONT,"Consolas");
   ObjectSet("MaxLotSize",OBJPROP_FONTSIZE,FontSize);
   if(AvailableLots > 0 && MarginRequired*TotalRiskOrderLots*100/AccountBalance() < MaxCapitalPercent/100)
   {
      if(TotalRiskOrderLots > 0)
      {
         ObjectSet("MaxLotSize",OBJPROP_COLOR,Yellow);
         Text_MaxLotSize=StringConcatenate(">>> ", DoubleToStr(AvailableLots,2), " <<<");
      }
      if(TotalRiskOrderLots == 0)
      {
         ObjectSet("MaxLotSize",OBJPROP_COLOR,Gold);
         if (TotalOpenOrderLots > 0.0)
            Text_MaxLotSize=StringConcatenate("(", DoubleToStr(MaxRiskLots,2), " | ", TotalOpenOrderLots, ")");
         else
            Text_MaxLotSize=StringConcatenate(">>> ", DoubleToStr(MaxRiskLots,2), " <<<");
      }
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
   ObjectSet("MaxStopLoss",OBJPROP_YDISTANCE,45);
   ObjectSetString(0,"MaxStopLoss",OBJPROP_FONT,"Consolas");
   ObjectSet("MaxStopLoss",OBJPROP_FONTSIZE,FontSize);
   ObjectSet("MaxStopLoss",OBJPROP_COLOR,Lime);
   Text_MaxStopLoss=StringConcatenate(DoubleToStr(MaxStopLossPips,0), " -> $", DoubleToStr(MaxStopLossAmount,2));
   ObjectSetText("MaxStopLoss",Text_MaxStopLoss);
   
   // Display weekly average swing range in pips & dollar amount
   ObjectCreate("SwingRange",OBJ_LABEL,0,0,0,0,0,0,0);
   ObjectSet("SwingRange",OBJPROP_CORNER,3);
   ObjectSet("SwingRange",OBJPROP_XDISTANCE,5);
   ObjectSet("SwingRange",OBJPROP_YDISTANCE,25);
   ObjectSetString(0,"SwingRange",OBJPROP_FONT,"Consolas");
   ObjectSet("SwingRange",OBJPROP_FONTSIZE,FontSize);
   ObjectSet("SwingRange",OBJPROP_COLOR,Orange);
   if(Period() < PERIOD_D1)
      Text_SwingRange=StringConcatenate(DoubleToStr(SwingRange_D1*nTimes,0), " -> $", DoubleToStr(SwingRange_D1*nTimes*PipValue*MaxRiskLots*100,2));
   else
      Text_SwingRange=StringConcatenate(DoubleToStr(SwingRange_W1*nTimes,0), " -> $", DoubleToStr(SwingRange_W1*nTimes*PipValue*MaxRiskLots*100,2));
   ObjectSetText("SwingRange",Text_SwingRange);
   
   // Display minimum margin required & pip value
   ObjectCreate("MarginRequired",OBJ_LABEL,0,0,0,0,0,0,0);
   ObjectSet("MarginRequired",OBJPROP_CORNER,3);
   ObjectSet("MarginRequired",OBJPROP_XDISTANCE,5);
   ObjectSet("MarginRequired",OBJPROP_YDISTANCE,5);
   ObjectSetString(0,"MarginRequired",OBJPROP_FONT,"Consolas");
   ObjectSet("MarginRequired",OBJPROP_FONTSIZE,FontSize);
   ObjectSet("MarginRequired",OBJPROP_COLOR,DeepSkyBlue);
   Text_MarginRequired=StringConcatenate("$", DoubleToStr(MarginRequired,2), " -> $", DoubleToStr(PipValue,2));
   ObjectSetText("MarginRequired",Text_MarginRequired);

   RefreshRates();   // automatically refresh the chart
   WindowRedraw();   // now redraw all
    
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+

void DrawGrid()
{
   firstTime = false;
   lastTime = CurTime();
            
   if (HGrid_Weeks > 0 && HGrid_Pips > 0)
   {
      double weekH = iHigh(NULL, PERIOD_W1, 0);
      double weekL = iLow(NULL, PERIOD_W1, 0);
               
      for (int i = 1; i < HGrid_Weeks; i++)
      {
         weekH = MathMax(weekH, iHigh( NULL, PERIOD_W1, i));
         weekL = MathMin(weekL, iLow( NULL, PERIOD_W1, i));
      }
            
      double pipRange = HGrid_Pips * Point;
      if (Period()>=PERIOD_D1) pipRange *= 10.0;
      if (Symbol() == "GOLD" || Symbol() == "CrudeOIL" || Symbol()=="WHEAT" || Symbol() == "SOYBEAN" ||  Symbol()=="CORN" || Symbol()=="HSI") pipRange *= 10.0;
      
      double topPips = (weekH + pipRange) - MathMod(weekH, pipRange);
      double botPips = weekL - MathMod(weekL, pipRange);
            
      for (double p = botPips; p <= topPips; p += pipRange) 
      {
         string gridname = "grid_" + DoubleToStr(p, Digits);
         ObjectCreate(gridname, OBJ_HLINE, 0, 0, p);
                  
         double pp = p / Point;
         int pInt = (int)MathRound(pp);
         int mod = 100;
         if ((pInt % mod) == 0)
            ObjectSet(gridname, OBJPROP_COLOR, HLine2);
         else
            ObjectSet(gridname, OBJPROP_COLOR, HLine);
         ObjectSet(gridname, OBJPROP_STYLE, STYLE_DASHDOTDOT);
         ObjectSet(gridname, OBJPROP_PRICE1, p);
         ObjectSet(gridname, OBJPROP_BACK, true);
      }     
   }
}