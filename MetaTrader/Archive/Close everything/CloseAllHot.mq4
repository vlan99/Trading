//+------------------------------------------------------------------+
//|                                                     CloseAll.mq4 |
//|                                         Developed by Coders Guru |
//|                                            http://www.xpworx.com |
//+------------------------------------------------------------------+

#property copyright "Coders Guru"
#property link      "http://www.xpworx.com"
#property show_inputs
//Last Modification = 2010.10.19 21:00


extern int option = 0;
//+------------------------------------------------------------------+
// Set this prameter to the type of clsoing you want:
// 0- Close all (instant and pending orders) (Default)
// 1- Close all instant orders
// 2- Close all pending orders
// 3- Close by the magic number
// 4- Close by comment
// 5- Close orders in profit
// 6- Close orders in loss
// 7- Close not today orders
//+------------------------------------------------------------------+

extern string help_magic_number = "set it if you'll use closing option 3 - closing by magic number";
extern int magic_number = 0; // set it if you'll use closing option 3 - closing by magic number
extern string help_comment_text = "set it if you'll use closing option 4 - closing by comment";
extern string comment_text = "";
extern bool HotKeyOn = true;
extern bool CtrlOn = true;
extern bool ShiftOn = false;
extern bool AltOn = false;
extern string HotKey = "A";


#import "user32.dll"
   bool      GetAsyncKeyState(int nVirtKey);
#import

#include <WinUser32.mqh> //for MessageBoxA

//---- MessageBox() Flags
#define MB_OK                       	0x00000000
#define MB_OKCANCEL                 	0x00000001
#define MB_ABORTRETRYIGNORE         	0x00000002
#define MB_YESNOCANCEL              	0x00000003
#define MB_YESNO                    	0x00000004
#define MB_RETRYCANCEL              	0x00000005
#define MB_ICONHAND                 	0x00000010
#define MB_ICONQUESTION             	0x00000020
#define MB_ICONEXCLAMATION          	0x00000030
#define MB_ICONASTERISK             	0x00000040
#define MB_USERICON                 	0x00000080
#define MB_ICONWARNING              	MB_ICONEXCLAMATION
#define MB_ICONERROR                	MB_ICONHAND
#define MB_ICONINFORMATION          	MB_ICONASTERISK
#define MB_ICONSTOP                 	MB_ICONHAND
#define MB_DEFBUTTON1               	0x00000000
#define MB_DEFBUTTON2               	0x00000100
#define MB_DEFBUTTON3               	0x00000200
#define MB_DEFBUTTON4               	0x00000300
#define MB_APPLMODAL                	0x00000000
#define MB_SYSTEMMODAL              	0x00001000
#define MB_TASKMODAL                	0x00002000
#define MB_HELP                     	0x00004000 // Help Button
#define MB_NOFOCUS                  	0x00008000
#define MB_SETFOREGROUND            	0x00010000
#define MB_DEFAULT_DESKTOP_ONLY     	0x00020000
#define MB_TOPMOST                  	0x00040000
#define MB_RIGHT                    	0x00080000
#define MB_RTLREADING               	0x00100000


#define KEYEVENTF_EXTENDEDKEY          0x0001
#define KEYEVENTF_KEYUP                0x0002

#define VK_0   48
#define VK_1   49
#define VK_2   50
#define VK_3   51
#define VK_4   52
#define VK_5   53
#define VK_6   54
#define VK_7   55
#define VK_8   56
#define VK_9   57
#define VK_A   65
#define VK_B   66
#define VK_C   67
#define VK_D   68
#define VK_E   69
#define VK_F   70
#define VK_G   71
#define VK_H   72
#define VK_I   73
#define VK_J   74
#define VK_K   75
#define VK_L   76
#define VK_M   77
#define VK_N   78
#define VK_O   79
#define VK_P   80
#define VK_Q   81
#define VK_R   82
#define VK_S   83
#define VK_T   84
#define VK_U   85
#define VK_V   86
#define VK_W   87
#define VK_X   88
#define VK_Y   89
#define VK_Z   90

#define VK_LBUTTON         1     //Left mouse button
#define VK_RBUTTON         2     //Right mouse button
#define VK_CANCEL          3     //Control-break processing
#define VK_MBUTTON         4     //Middle mouse button (three-button mouse)
#define VK_BACK            8     //BACKSPACE key
#define VK_TAB             9     //TAB key
#define VK_CLEAR           12    //CLEAR key
#define VK_RETURN          13    //ENTER key
#define VK_SHIFT           16    //SHIFT key
#define VK_CONTROL         17    //CTRL key
#define VK_MENU            18    //ALT key
#define VK_PAUSE           19    //PAUSE key
#define VK_CAPITAL         20    //CAPS LOCK key
#define VK_ESCAPE          27    //ESC key
#define VK_SPACE           32    //SPACEBAR
#define VK_PRIOR           33    //PAGE UP key
#define VK_NEXT            34    //PAGE DOWN key
#define VK_END             35    //END key
#define VK_HOME            36    //HOME key
#define VK_LEFT            37    //LEFT ARROW key
#define VK_UP              38    //UP ARROW key
#define VK_RIGHT           39    //RIGHT ARROW key
#define VK_DOWN            40    //DOWN ARROW key
#define VK_PRINT           42    //PRINT key
#define VK_SNAPSHOT        44    //PRINT SCREEN key
#define VK_INSERT          45    //INS key
#define VK_DELETE          46    //DEL key
#define VK_HELP            47    //HELP key
#define VK_LWIN            91    //Left Windows key (Microsoft® Natural® keyboard)
#define VK_RWIN            92    //Right Windows key (Natural keyboard)
#define VK_APPS            93    //Applications key (Natural keyboard)
#define VK_SLEEP           95    //Computer Sleep key
#define VK_NUMPAD0         96    //Numeric keypad 0 key
#define VK_NUMPAD1         97    //Numeric keypad 1 key
#define VK_NUMPAD2         98    //Numeric keypad 2 key
#define VK_NUMPAD3         99    //Numeric keypad 3 key
#define VK_NUMPAD4         100   //Numeric keypad 4 key
#define VK_NUMPAD5         101   //Numeric keypad 5 key
#define VK_NUMPAD6         102   //Numeric keypad 6 key
#define VK_NUMPAD7         103   //Numeric keypad 7 key
#define VK_NUMPAD8         104   //Numeric keypad 8 key
#define VK_NUMPAD9         105   //Numeric keypad 9 key
#define VK_MULTIPLY        106   //Multiply key
#define VK_ADD             107   //Add key
#define VK_SEPARATOR       108   //Separator key
#define VK_SUBTRACT        109   //Subtract key
#define VK_DECIMAL         110   //Decimal key
#define VK_DIVIDE          111   //Divide key
#define VK_F1              112   //F1 key
#define VK_F2              113   //F2 key
#define VK_F3              114   //F3 key
#define VK_F4              115   //F4 key
#define VK_F5              116   //F5 key
#define VK_F6              117   //F6 key
#define VK_F7              118   //F7 key
#define VK_F8              119   //F8 key
#define VK_F9              120   //F9 key
#define VK_F10             121   //F10 key
#define VK_F11             122   //F11 key
#define VK_F12             123   //F12 key
#define VK_F13             124   //F13 key
#define VK_NUMLOCK         144   //NUM LOCK key
#define VK_SCROLL          145   //SCROLL LOCK key
#define VK_LSHIFT          160   //Left SHIFT key
#define VK_RSHIFT          161   //Right SHIFT key
#define VK_LCONTROL        162   //Left CONTROL key
#define VK_RCONTROL        163   //Right CONTROL key
#define VK_LMENU           164   //Left MENU key
#define VK_RMENU           165   //Right MENU key

int tHot = 0;

void Hook()
{
  int result = -1;
  if(CtrlOn == true && ShiftOn == false && AltOn == false)
   {
      if(GetAsyncKeyState(VK_CONTROL) && GetAsyncKeyState(tHot))
      {
         if(MessageBoxA(NULL,"Are you sure want to close all the trades?","Confirm",MB_YESNO)==6)
         CloseAll();
      }
   }
   if(CtrlOn == true && ShiftOn == true && AltOn == false)
   {
      if(GetAsyncKeyState(VK_CONTROL) && GetAsyncKeyState(VK_SHIFT) && GetAsyncKeyState(tHot))
      {
         if(MessageBoxA(NULL,"Are you sure want to close all the trades?","Confirm",MB_YESNO)==6)
         CloseAll();
      }
   }
   if(CtrlOn == true && ShiftOn == true && AltOn == true)
   {
      if(GetAsyncKeyState(VK_CONTROL) && GetAsyncKeyState(VK_SHIFT) && GetAsyncKeyState(VK_MENU) && GetAsyncKeyState(tHot))
      {
         if(MessageBoxA(NULL,"Are you sure want to close all the trades?","Confirm",MB_YESNO)==6)
         CloseAll();
      }
   }
   if(CtrlOn == false && ShiftOn == true && AltOn == true)
   {
      if(GetAsyncKeyState(VK_SHIFT) && GetAsyncKeyState(VK_MENU) && GetAsyncKeyState(tHot))
      {
         if(MessageBoxA(NULL,"Are you sure want to close all the trades?","Confirm",MB_YESNO)==6)
         CloseAll();
      }
   }
   if(CtrlOn == false && ShiftOn == true && AltOn == false)
   {
      if(GetAsyncKeyState(VK_SHIFT) && GetAsyncKeyState(tHot))
      {
         if(MessageBoxA(NULL,"Are you sure want to close all the trades?","Confirm",MB_YESNO)==6)
         CloseAll();
      }
   }
   if(CtrlOn == false && ShiftOn == false && AltOn == true)
   {
      if(GetAsyncKeyState(VK_MENU) && GetAsyncKeyState(tHot))
      {
         if(MessageBoxA(NULL,"Are you sure want to close all the trades?","Confirm",MB_YESNO)==6)
         CloseAll();
      }
   }
   if(CtrlOn == false && ShiftOn == false && AltOn == false)
   {
      if(GetAsyncKeyState(tHot))
      {
         if(MessageBoxA(NULL,"Are you sure want to close all the trades?","Confirm",MB_YESNO)==6)
         CloseAll();
      }
   }
}

void timer() 
{

   while(true) 
   {
      Sleep(1000);
      if(IsStopped()) 
      {
         return;
      }
      start();
   }
   
}
int init()
{
   tHot = GetHotKey(HotKey);
   timer();
}


int start()
{
   Hook();
   return(0);
}
//+------------------------------------------------------------------+

int CloseAll()
{
   int total = OrdersTotal();
   int cnt = 0;
 
   switch (option)
   {
      case 0:
      {
         for (cnt = total ; cnt >=0 ; cnt--)
         {
            OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
            CloseOrder(OrderTicket(),OrderType());
         }
         break;
      }
      case 1:
      {
         for (cnt = total ; cnt >=0 ; cnt--)
         {
            OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
            if(OrderType()==OP_BUY || OrderType()==OP_SELL)
            CloseOrder(OrderTicket(),OrderType());
         }
         break;
      }
      case 2:
      {
         for (cnt = total ; cnt >=0 ; cnt--)
         {
            OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
            if(OrderType()>OP_SELL)
            CloseOrder(OrderTicket(),OrderType());
         }
         break;
      }
      case 3:
      {
         for (cnt = total ; cnt >=0 ; cnt--)
         {
            OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
            if (OrderMagicNumber() == magic_number)
            {
               CloseOrder(OrderTicket(),OrderType());
            }
         }         
         break;
      }
      case 4:
      {
         for (cnt = total ; cnt >=0 ; cnt--)
         {
            OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
            if (OrderComment() == comment_text)
            {
               CloseOrder(OrderTicket(),OrderType());
            }
         }         
         break;
      }
      case 5:
      {
         for (cnt = total ; cnt >=0 ; cnt--)
         {
            OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
            if (OrderProfit() > 0)
            {
               CloseOrder(OrderTicket(),OrderType());
            }
         }         
         break;
      }
      case 6:
      {
         for (cnt = total ; cnt >=0 ; cnt--)
         {
            OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
            if (OrderProfit() < 0)
            {
               CloseOrder(OrderTicket(),OrderType());
            }
         }         
         break;
      }
      case 7:
      {
         for (cnt = total ; cnt >=0 ; cnt--)
         {
            OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
            if (TimeDay(OrderOpenTime()) < TimeDay(CurTime()))
            {
               CloseOrder(OrderTicket(),OrderType());
            }
         }         
         break;
      }
   }
}

bool CloseOrder(int tick, int type)
{
   bool result;
   int tries = 5;
   int pause = 500;
   double ask = NormalizeDouble(Ask,Digits);
   double bid = NormalizeDouble(Bid,Digits);

   if(OrderSelect(tick,SELECT_BY_TICKET,MODE_TRADES))
   {
      
      if(type==OP_BUY)
      {
         for(int c = 0 ; c <= tries ; c++)
         {
            result = OrderClose(OrderTicket(),OrderLots(),bid,5,Violet);
            if(result==true) break; 
            else
            {
               Sleep(pause);
               continue;
            }
         }
      }
      if(type==OP_SELL)
      {
         for(c = 0 ; c <= tries ; c++)
         {
            result = OrderClose(OrderTicket(),OrderLots(),ask,5,Violet);
            if(result==true) break; 
            else
            {
               Sleep(pause);
               continue;
            }
         }
      }
      if(OrderType()>OP_SELL)
      {
         for(c = 0 ; c <= tries ; c++)
         {
            result = OrderDelete(OrderTicket());
            if(result==true) break; 
            else
            {
               Sleep(pause);
               continue;
            }
         }
      }
   }
   return(result);
}

int GetHotKey(string HotKey)
{
   if (StringFind(StringUpperCase(HotKey),"0")>-1) return(VK_0);
   if (StringFind(StringUpperCase(HotKey),"1")>-1) return(VK_1);
   if (StringFind(StringUpperCase(HotKey),"2")>-1) return(VK_2);
   if (StringFind(StringUpperCase(HotKey),"3")>-1) return(VK_3);
   if (StringFind(StringUpperCase(HotKey),"4")>-1) return(VK_4);
   if (StringFind(StringUpperCase(HotKey),"5")>-1) return(VK_5);
   if (StringFind(StringUpperCase(HotKey),"6")>-1) return(VK_6);
   if (StringFind(StringUpperCase(HotKey),"7")>-1) return(VK_7);
   if (StringFind(StringUpperCase(HotKey),"8")>-1) return(VK_8);
   if (StringFind(StringUpperCase(HotKey),"9")>-1) return(VK_9);
   if (StringFind(StringUpperCase(HotKey),"A")>-1) return(VK_A);
   if (StringFind(StringUpperCase(HotKey),"B")>-1) return(VK_B);
   if (StringFind(StringUpperCase(HotKey),"C")>-1) return(VK_C);
   if (StringFind(StringUpperCase(HotKey),"D")>-1) return(VK_D);
   if (StringFind(StringUpperCase(HotKey),"E")>-1) return(VK_E);
   if (StringFind(StringUpperCase(HotKey),"F")>-1) return(VK_F);
   if (StringFind(StringUpperCase(HotKey),"G")>-1) return(VK_G);
   if (StringFind(StringUpperCase(HotKey),"H")>-1) return(VK_H);
   if (StringFind(StringUpperCase(HotKey),"I")>-1) return(VK_I);
   if (StringFind(StringUpperCase(HotKey),"J")>-1) return(VK_J);
   if (StringFind(StringUpperCase(HotKey),"K")>-1) return(VK_K);
   if (StringFind(StringUpperCase(HotKey),"L")>-1) return(VK_L);
   if (StringFind(StringUpperCase(HotKey),"M")>-1) return(VK_M);
   if (StringFind(StringUpperCase(HotKey),"N")>-1) return(VK_N);
   if (StringFind(StringUpperCase(HotKey),"O")>-1) return(VK_O);
   if (StringFind(StringUpperCase(HotKey),"P")>-1) return(VK_P);
   if (StringFind(StringUpperCase(HotKey),"Q")>-1) return(VK_Q);
   if (StringFind(StringUpperCase(HotKey),"R")>-1) return(VK_R);
   if (StringFind(StringUpperCase(HotKey),"S")>-1) return(VK_S);
   if (StringFind(StringUpperCase(HotKey),"T")>-1) return(VK_T);
   if (StringFind(StringUpperCase(HotKey),"U")>-1) return(VK_U);
   if (StringFind(StringUpperCase(HotKey),"V")>-1) return(VK_V);
   if (StringFind(StringUpperCase(HotKey),"W")>-1) return(VK_W);
   if (StringFind(StringUpperCase(HotKey),"X")>-1) return(VK_X);
   if (StringFind(StringUpperCase(HotKey),"Y")>-1) return(VK_Y);
   if (StringFind(StringUpperCase(HotKey),"Z")>-1) return(VK_Z);
}

string StringUpperCase(string str)
{
   int s = StringLen(str);
   int chr = 0;
   string temp;
   for (int c = 0 ; c < s ; c++)
   {
      chr = StringGetChar(str,c);
      if (chr >= 97 && chr <=122) chr = chr - 32;
      temp = temp + CharToStr(chr);
   }
   return (temp);  
}

