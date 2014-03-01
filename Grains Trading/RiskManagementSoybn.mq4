//+------------------------------------------------------------------+
//|                                          RiskManagementSoybn.mq4 |
//|                                      Copyright 2014, Junjie Tang |
//|                                            razorsniper@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

#property indicator_chart_window

//---- input parameters
extern int    FontSize=10;
extern int    MicroLotUnit=6;
extern double MaxRiskPercentage=0.01;
extern double Spread=3.0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
//---- indicators
//----
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
//----
    return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
{
    if(StringFind(Symbol(),"SOYBN",0)<0) return(0);
    
    RefreshRates();   // automatically refresh the chart
    WindowRedraw();   // now redraw all
//----
    double SwingRange_MN1 = 0.0, SwingRange_W1 = 0.0, SwingRange_D1 = 0.0, SwingRange_H4 = 0.0, SwingRange_H1 = 0.0;
    double SwingRange_M30 = 0.0, SwingRange_M15 = 0.0, SwingRange_M5 = 0.0, SwingRange_M1 = 0.0, MarginRequired = 0.0, MaxStopLoss = 0.0;
    double MaxRiskCapitalSize = 0.0, MaxRiskLots = 0.0, AvailableLots = 0.0, TotalOpenOrderLots = 0.0, TotalOrderRiskLots = 0.0;
    string Text_MaxLotSize= "", Text_MaxStopLoss = "";

    // Total open order lots without risk
    for(int i=0; i<OrdersTotal(); i++) 
    {
        if(!OrderSelect(i,SELECT_BY_POS)) continue;
        
        if (StringFind(OrderSymbol(),"SOYBN",0)>=0)
        {
            TotalOpenOrderLots+=OrderLots();
            if (OrderStopLoss()!=0) 
            {
               if (OrderType() == OP_BUY && OrderStopLoss() - OrderOpenPrice() >= 0) continue;
               if (OrderType() == OP_SELL && OrderOpenPrice() - OrderStopLoss() >= 0) continue;
            }
            TotalOrderRiskLots+=OrderLots();
        }
    }

    // Calculate average price swing range
    for(i=1; i<=240; i++) 
    {
        SwingRange_MN1 += (iHigh(NULL,PERIOD_MN1,i) - iLow(NULL,PERIOD_MN1,i)) / Point;
        SwingRange_W1 += (iHigh(NULL, PERIOD_W1, i) - iLow(NULL, PERIOD_W1, i)) / Point;
        SwingRange_D1 += (iHigh(NULL, PERIOD_D1, i) - iLow(NULL, PERIOD_D1, i)) / Point;
        SwingRange_H4 += (iHigh(NULL, PERIOD_H4, i) - iLow(NULL, PERIOD_H4, i)) / Point;
        SwingRange_H1 += (iHigh(NULL, PERIOD_H1, i) - iLow(NULL, PERIOD_H1, i)) / Point;
        SwingRange_M30 += (iHigh(NULL, PERIOD_M30, i) - iLow(NULL, PERIOD_M30, i)) / Point;
        SwingRange_M15 += (iHigh(NULL, PERIOD_M15, i) - iLow(NULL, PERIOD_M15, i)) / Point;
        SwingRange_M5 += (iHigh(NULL, PERIOD_M5, i) - iLow(NULL, PERIOD_M5, i)) / Point;
        SwingRange_M1 += (iHigh(NULL, PERIOD_M1, i) - iLow(NULL, PERIOD_M1, i)) / Point;

        if(i==240) 
        {
            SwingRange_MN1/= i;
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
    if (Period()<PERIOD_D1) 
        MaxStopLoss=SwingRange_D1+Spread;
    else
        MaxStopLoss=SwingRange_W1+Spread;

    // Calculate margin required for 1 micro lot (0.01)
    MarginRequired=MarketInfo(Symbol(),MODE_MARGINREQUIRED)*0.01;

    // Calulate maximum risk capital size
    MaxRiskCapitalSize=(AccountEquity()-AccountMargin())*MaxRiskPercentage+MarginRequired;

    // Calculate maximum risk lots
    MaxRiskLots=(MaxRiskCapitalSize/MaxStopLoss*MicroLotUnit)*0.01;
    if (MaxRiskLots==0.0) MaxRiskLots=0.01;

    // Calculate available lots
    AvailableLots=MaxRiskLots-TotalOrderRiskLots;

    // Display maximume lot size available
    ObjectCreate("MaxLotSize",OBJ_LABEL,0,0,0,0,0,0,0);
    ObjectSet("MaxLotSize",OBJPROP_CORNER,1);
    ObjectSet("MaxLotSize",OBJPROP_XDISTANCE,5);
    ObjectSet("MaxLotSize",OBJPROP_YDISTANCE,5);
    ObjectSet("MaxLotSize",OBJPROP_FONT,"Consolas");
    ObjectSet("MaxLotSize",OBJPROP_FONTSIZE,FontSize);
    if (AvailableLots > 0)
    {
       ObjectSet("MaxLotSize",OBJPROP_COLOR,Gold);
       Text_MaxLotSize=DoubleToStr(AvailableLots,2);
    }
    else
    {  
       ObjectSet("MaxLotSize",OBJPROP_COLOR,Lavender);
       Text_MaxLotSize="Too risky!";
    }
    if(TotalOpenOrderLots!=0 && TotalOrderRiskLots==0) 
    {
        ObjectSet("MaxLotSize",OBJPROP_FONT,"Consolas");
        ObjectSet("MaxLotSize",OBJPROP_FONTSIZE,FontSize);
        ObjectSet("MaxLotSize",OBJPROP_COLOR,Lime);
        Text_MaxLotSize=DoubleToStr(MaxRiskLots,2);
    }
    ObjectSetText("MaxLotSize",Text_MaxLotSize);
    
    // Display maximum stop loss in pips
    ObjectCreate("MaxStopLoss",OBJ_LABEL,0,0,0,0,0,0,0);
    ObjectSet("MaxStopLoss",OBJPROP_CORNER,2);
    ObjectSet("MaxStopLoss",OBJPROP_XDISTANCE,5);
    ObjectSet("MaxStopLoss",OBJPROP_YDISTANCE,5);
    ObjectSet("MaxStopLoss",OBJPROP_FONT,"Consolas");
    ObjectSet("MaxStopLoss",OBJPROP_FONTSIZE,FontSize);
    ObjectSet("MaxStopLoss",OBJPROP_COLOR,DodgerBlue);
    Text_MaxStopLoss=StringConcatenate("S/L: ",StringConcatenate(DoubleToStr(MaxStopLoss,1)," / $",DoubleToStr((AccountEquity()-AccountMargin())*MaxRiskPercentage,2)));
    ObjectSetText("MaxStopLoss",Text_MaxStopLoss);

    RefreshRates();   // automatically refresh the chart
    WindowRedraw();   // now redraw all

//----
    return(0);
}
//+------------------------------------------------------------------+
