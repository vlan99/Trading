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
extern double MaxCapitalPercent=30.0;    // Maximum capital percent allowed to be used
extern int    FontSize=10;               // Risk management label text size
extern int    HGrid_Weeks=2;             // Period over which to calc High/Low of gird (in week)
extern int    HGrid_Pips=10000;          // Size of grid in Pips (1000.0)
extern color  HLine=LightSlateGray;      // Color of grid
extern color  HLine2=LightSlateGray;     // Every 100 pips, change grid color to this.
extern bool   EnableGrid=true;           // Grid On/Off


// Recommends settings:
// 1 minute - HGrid_Pips=10, TimeGrid = 10
// 5, 15 minutes - HGrid_Pips=20, TimeGrid= PERIOD_H1 (60)
// 30, 60 minutes - HGrid_Pips=20, TimeGrid = PERIOD_H4 (240) or 2 hours (120)
// 4 hour - HGrid_Pips=50, TimeGrid = PERIOD_D1 (1440) or 12 hours (720)
// 1 day - HGrid_Pips=50, TimeGrid = PERIOD_W1 (10800).

bool firstTime = true;
datetime lastTime = 0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
//--- indicator buffers mapping
//---
   return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
{
//----
   ObjectDelete("MaxLotSize");
   ObjectDelete("MaxStopLoss");
   for ( int i = ObjectsTotal() - 1; i >= 0; i-- ) {
      string name = ObjectName( i );
      if ( StringFind( name, "grid_" ) >= 0 ) 
         ObjectDelete( name );
   }
//----
   return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
{
//----
    RefreshRates();   // automatically refresh the chart
    WindowRedraw();   // now redraw all
    
    int i = 0, TotalBarCount = 0, nTimes = 0;
    double SwingRange = 0.0, SwingRange_W1 = 0.0, SwingRange_D1 = 0.0, SwingRange_H1 = 0.0, MarginRequired = 0.0, MaxStopLoss = 0.0, OneKStopLoss = 0.0, PipValue = 0.0, MaxSpread = 0.0;
    double RunningRiskPercent = 0.0, CapitalMaxRiskAmount = 0.0, MaxRiskLots = 0.0, AvailableLots = 0.0, TotalOpenOrderLots = 0.0, TotalOpenOrderProfit = 0.0, TotalOrderRiskLots = 0.0, TotalRiskOrderProfit = 0.0;
    string Text_MaxLotSize= "", Text_MaxStopLoss = "";

    // Total open order lots without risk
    for(i=0; i<OrdersTotal(); i++) 
    {
        if(!OrderSelect(i,SELECT_BY_POS)) continue;
        TotalOpenOrderLots+=OrderLots();
        TotalOpenOrderProfit+=OrderProfit();
        if (OrderStopLoss()!=0) 
        {
           if(OrderType() == OP_BUY && OrderStopLoss() - OrderOpenPrice() >= 0) continue;
           if(OrderType() == OP_SELL && OrderOpenPrice() - OrderStopLoss() >= 0) continue;
        }
        if(Symbol() == OrderSymbol())
        {
           TotalOrderRiskLots+=OrderLots();
           TotalRiskOrderProfit+=OrderProfit();
        }
    }
    
    // Calculate base info
    switch(Digits)
    {
       case 5:
          nTimes=100000;
          break;
       case 3:
          nTimes=1000;
          break;
       case 2:
          nTimes=100;
          break;
       case 1:
          nTimes=10;
          break;
    }
   
    // Calculate average price swing range
    TotalBarCount = 300;
    for(i=1; i<=TotalBarCount; i++) 
    {
        SwingRange_W1 += (iHigh(NULL, PERIOD_W1, i) - iLow(NULL, PERIOD_W1, i));
        SwingRange_D1 += (iHigh(NULL, PERIOD_D1, i) - iLow(NULL, PERIOD_D1, i));
        SwingRange_H1 += (iHigh(NULL, PERIOD_H1, i) - iLow(NULL, PERIOD_H1, i));
    }
    SwingRange_W1 /= TotalBarCount;
    SwingRange_D1 /= TotalBarCount;
    SwingRange_H1 /= TotalBarCount;
    
    // Calculate maximum stop loss in pips
    MaxSpread=MarketInfo(Symbol(),MODE_SPREAD)*Point*2;
    OneKStopLoss=(SwingRange_H1+MaxSpread)*(double)nTimes;
    MaxStopLoss=(SwingRange_D1+MaxSpread)*(double)nTimes;
    SwingRange=SwingRange_W1*(double)nTimes;
        
    // Calculate pip value for 1 micro lot (0.01)
    PipValue=MarketInfo(Symbol(),MODE_TICKVALUE)*0.01;

    // Calculate margin required for 1 micro lot (0.01)
    MarginRequired=MarketInfo(Symbol(),MODE_MARGINREQUIRED)*0.01;

    // Calulate maximum risk capital size
    CapitalMaxRiskAmount=AccountBalance()*(MaxPerRiskPercent/100.0);

    // Calculate maximum risk lots
    MaxRiskLots=MathFloor(CapitalMaxRiskAmount/(MaxStopLoss*PipValue))*0.01;

    // Calculate available lots
    AvailableLots=MaxRiskLots-TotalOrderRiskLots;
    
    // Calculate total capital risk percent
    RunningRiskPercent=(TotalRiskOrderProfit/AccountBalance())*100;

    // Display maximume lot size available
    ObjectCreate("MaxLotSize",OBJ_LABEL,0,0,0,0,0,0,0);
    ObjectSet("MaxLotSize",OBJPROP_CORNER,1);
    ObjectSet("MaxLotSize",OBJPROP_XDISTANCE,5);
    ObjectSet("MaxLotSize",OBJPROP_YDISTANCE,5);
    ObjectSetString(0,"MaxLotSize",OBJPROP_FONT,"Consolas");
    ObjectSet("MaxLotSize",OBJPROP_FONTSIZE,FontSize);
    if(AvailableLots > 0 && TotalOrderRiskLots < MaxRiskLots && RunningRiskPercent < MaxPerRiskPercent && AccountMargin()/AccountBalance() < MaxCapitalPercent/100.0)
    {
       if(TotalOrderRiskLots > 0)
       {
          ObjectSet("MaxLotSize",OBJPROP_COLOR,Yellow);
          Text_MaxLotSize=StringConcatenate("Risk: ", DoubleToString(TotalOrderRiskLots,2), " | ", DoubleToString(AvailableLots,2));
       }
       if(TotalOrderRiskLots == 0)
       {
          ObjectSet("MaxLotSize",OBJPROP_COLOR,Gold);
          Text_MaxLotSize=StringConcatenate("Risk: ", DoubleToString(MaxRiskLots,2), " | $", DoubleToString(MarginRequired,2), " (", DoubleToString(MathFloor((MaxRiskLots*100)/2)*0.01,2), ")");
       }
    }
    else
    {  
       ObjectSet("MaxLotSize",OBJPROP_COLOR,Lavender);
       Text_MaxLotSize=StringConcatenate("Too risky! -> ", DoubleToString(TotalOrderRiskLots,2), " | ", DoubleToString((MaxStopLoss*PipValue*TotalOrderRiskLots*100/AccountFreeMargin())*100,1), "%");
    }
    ObjectSetText("MaxLotSize",Text_MaxLotSize);
    
    // Display maximum stop loss in pips
    ObjectCreate("MaxStopLoss",OBJ_LABEL,0,0,0,0,0,0,0);
    ObjectSet("MaxStopLoss",OBJPROP_CORNER,3);
    ObjectSet("MaxStopLoss",OBJPROP_XDISTANCE,5);
    ObjectSet("MaxStopLoss",OBJPROP_YDISTANCE,5);
    ObjectSetString(0,"MaxStopLoss",OBJPROP_FONT,"Consolas");
    ObjectSet("MaxStopLoss",OBJPROP_FONTSIZE,FontSize);
    ObjectSet("MaxStopLoss",OBJPROP_COLOR,DodgerBlue);
    if(TotalOrderRiskLots==0) TotalOrderRiskLots=MaxRiskLots;
    Text_MaxStopLoss=StringConcatenate("S/L: ",DoubleToString(OneKStopLoss,0), " | $", DoubleToString(MaxStopLoss*PipValue*TotalOrderRiskLots*100,2), " | ", DoubleToString(RunningRiskPercent,1), "% (", DoubleToString(MaxStopLoss,0), " -> ", DoubleToString(SwingRange,0), ")");
    ObjectSetText("MaxStopLoss",Text_MaxStopLoss);

    RefreshRates();   // automatically refresh the chart
    WindowRedraw();   // now redraw all
    
    // Round number grid
    if (EnableGrid)
    {
       if (true /*lastTime == 0 || CurTime() - lastTime > 5*/)
       {
          firstTime = false;
          lastTime = CurTime();
            
          if (HGrid_Weeks > 0 && HGrid_Pips > 0)
          {
             double weekH = iHigh(NULL, PERIOD_W1, 0);
             double weekL = iLow(NULL, PERIOD_W1, 0);
               
             for (i = 1; i < HGrid_Weeks; i++)
             {
                weekH = MathMax(weekH, iHigh( NULL, PERIOD_W1, i));
                weekL = MathMin(weekL, iLow( NULL, PERIOD_W1, i));
             }
            
             double pipRange = HGrid_Pips * Point;
             if (Period()>=PERIOD_D1) pipRange = pipRange * 10.0;
      
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
    }
//---
   return(0);
}
//+------------------------------------------------------------------+
