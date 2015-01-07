//+------------------------------------------------------------------+
//|                                           Time_Vertical_Line.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property show_inputs

extern string hour = "22";
extern int width = 2;
extern color Color = FireBrick;

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
  {
//----
   
      if (ObjectFind("Time_Vertical_Line") > -1)
      {
         ObjectDelete("Time_Vertical_Line");
      }
      
      datetime time = StrToTime(TimeToStr(TimeCurrent(), TIME_DATE) + " " + hour + ":00");
      
      ObjectCreate("Time_Vertical_Line", OBJ_VLINE, 0, time, 0);
      ObjectSet("Time_Vertical_Line", OBJPROP_WIDTH, width);
      ObjectSet("Time_Vertical_Line", OBJPROP_COLOR, Color);
      ObjectSet("Time_Vertical_Line", OBJPROP_BACK, true);
   
//----as "yyyy.mm.dd hh:mi".
   return(0);
  }
//+------------------------------------------------------------------+