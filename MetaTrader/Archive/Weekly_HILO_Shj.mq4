//+------------------------------------------------------------------+
//|                                                 Weekly_HILO_Shj  |
//|                                                                  |
//|                                         http://www.metaquotes.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright ?2005, "
#property link      "http://"
//----
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1 Orange
#property indicator_color2 DeepSkyBlue
#property indicator_color3 LimeGreen
#property indicator_width1 1
#property indicator_width2 1
#property indicator_width3 1
#property indicator_style1 1
#property indicator_style2 1
#property indicator_style3 4
//---- input parameters
//---- buffers
extern bool EnableWeeklyHILO=true;
extern int space=44;
double PrevWeekHiBuffer[];
double PrevWeekLoBuffer[];
double PrevWeekMidBuffer[];
int fontsize=10;
double x;
double PrevWeekHi, PrevWeekLo, LastWeekHi, LastWeekLo,PrevWeekMid;
string Space;
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
   ObjectDelete("PrevWeekHi");
   ObjectDelete("PrevWeekLo");
   ObjectDelete("PrevWeekMid");
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   string short_name;
   int y;
//----
   SetIndexStyle(0,DRAW_LINE);
   SetIndexStyle(1,DRAW_LINE);
   SetIndexStyle(2,DRAW_LINE);
   SetIndexBuffer(0, PrevWeekHiBuffer);
   SetIndexBuffer(1, PrevWeekLoBuffer);
   SetIndexBuffer(2, PrevWeekMidBuffer);
   short_name="Prev Hi-Lo levels";
   IndicatorShortName(short_name);
   SetIndexLabel(0, short_name);
   SetIndexDrawBegin(0,1);
//----
   for(y=0;y<=space;y++)
     {
      Space=Space+" ";
     }
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   if(!EnableWeeklyHILO) return(0);
   if(Period()>PERIOD_H4) return(0);
   int counted_bars=IndicatorCounted();
   int limit, i;
   if (counted_bars==0)
     {
      x=Period();
      if (x>240) return(-1);
      ObjectCreate("PrevWeekHi", OBJ_TEXT, 0, 0, 0);
      ObjectSetText("PrevWeekHi", Space+"Week High",fontsize,"Arial", Tomato);
      ObjectCreate("PrevWeekLo", OBJ_TEXT, 0, 0, 0);
      ObjectSetText("PrevWeekLo", Space+"Week Low",fontsize,"Arial", DeepSkyBlue);
      ObjectCreate("PrevWeekMid", OBJ_TEXT, 0, 0, 0);
      ObjectSetText("PrevWeekMid", Space+"50% Hi-Low",fontsize,"Arial", LimeGreen);
     }
   limit=(Bars-counted_bars)-1;
   for(i=limit; i>=0;i--)
     {
      if (High[i+1]>LastWeekHi) LastWeekHi=High[i+1];
      if (Low [i+1]<LastWeekLo) LastWeekLo=Low [i+1];
      if (TimeDay(Time[i])!=TimeDay(Time[i+1]))
        {
         if(TimeDayOfWeek(Time[i])==1)
           {
            PrevWeekHi =LastWeekHi;
            PrevWeekLo =LastWeekLo;
            LastWeekHi =Open[i];
            LastWeekLo =Open[i];
            PrevWeekMid=(PrevWeekHi + PrevWeekLo)/2;
           }
        }
      PrevWeekHiBuffer [i]=PrevWeekHi;
      PrevWeekLoBuffer [i]=PrevWeekLo;
      PrevWeekMidBuffer[i]=PrevWeekMid;
//----
      ObjectMove("PrevWeekHi" , 0, Time[i], PrevWeekHi);
      ObjectSetText("PrevWeekHi", Space+"Week High: "+DoubleToString(PrevWeekHi,Digits),fontsize,"Arial", Tomato);
      ObjectMove("PrevWeekLo" , 0, Time[i], PrevWeekLo);
      ObjectSetText("PrevWeekLo", Space+"Week Low: "+DoubleToString(PrevWeekLo,Digits),fontsize,"Arial", DeepSkyBlue);
      ObjectMove("PrevWeekMid", 0, Time[i], PrevWeekMid);
      ObjectSetText("PrevWeekMid", Space+"50% Hi-Low: "+DoubleToString(PrevWeekMid,Digits),fontsize,"Arial", LimeGreen);
     }

   return(0);
  }
//+------------------------------------------------------------------+