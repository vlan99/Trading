//+------------------------------------------------------------------+
//|                                           Time_Vertical_Line.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property show_inputs

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
  {
//---- 
      datetime nextHour = Time[0]+900+180;
      ObjectCreate("Time_Vertical_Line_1H", OBJ_VLINE, 0, nextHour, 0);
      ObjectSet("Time_Vertical_Line_1H", OBJPROP_WIDTH, 1);
      ObjectSet("Time_Vertical_Line_1H", OBJPROP_COLOR, Magenta);
      ObjectSet("Time_Vertical_Line_1H", OBJPROP_STYLE, STYLE_DASHDOT);      
      ObjectSet("Time_Vertical_Line_1H", OBJPROP_BACK, true);
//----
   return(0);
  }
//+------------------------------------------------------------------+