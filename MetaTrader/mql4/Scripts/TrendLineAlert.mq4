//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){

   while (!IsStopped()){

      Comment("\n\n TrendLineAlert running ", TimeToStr(TimeLocal(), TIME_DATE|TIME_SECONDS));
      for(int i = ObjectsTotal()-1; i >= 0; i--){
         string name = ObjectName(i);
         if(ObjectType(name) == OBJ_TREND){
            double value = ObjectGetValueByShift(name, 0);
            if(Bid <= value + 1*Point && Bid >= value -1*Point){
               PlaySound("Alert2.wav");
            }
         }
      }
      Sleep(2000);
   }
   return(0);
}