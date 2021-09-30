//+------------------------------------------------------------------+
//|                                          AuxjumperAutoTrader.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//--- input parameters

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Indicators\Indicators.mqh>


CTrade Trade_trade;
CPositionInfo Trade_position;
CSymbolInfo Trade_symbolinfo;
CiATR atr;

input double   RiskPercentage=2.0;
input double   TPTargetMultiplier=2.0;
input double   SLTargetMultiplier=2.0;
input int      FastMovingAverage=100;
input int      SlowMovingAverage=500;
input int      CandleMagicNumber=20;
input datetime NoTradeTimeStart;
input datetime NoTradeTimeEnd;
input int      CandleMagicTooMuch=50;
input double   StopLoss=0.00030;
input double   TakeProfit=0.00040;

int EA_Magic = 475586;
double Lot = 1.0;
double STP = StopLoss;
double TKP = TakeProfit;   // To be used for Stop Loss & Take Profit values


int FastMAHandle;
int SlowMAHandle;
int handle_HMA_Custom;
int handle_WAE_Custom;
int handle_KELTNER_Custom;
int handle_TDFI_Custom;

      //--- Define some MQL5 Structures we will use for our trade
            MqlTick latest_price;     // To be used for getting recent/latest price quotes
            MqlTradeRequest mrequest;  // To be used for sending our trade requests
            MqlTradeResult mresult;    // To be used to get our trade results
            MqlRates mrate[];         // To be used to store the prices, volumes and spread of each bar
            

double p_close; // Variable to store the close value of a bar
double p_open;
double p_high;
double p_low;
double p_openclose_diff;

double maFastVal[]; // Dynamic array to hold the values of Fast Moving Average for each bars
double maSlowVal[]; // Dynamic array to hold the values of Slow Moving Average for each bars
double hmaValData[];
double hmaValColor[];
double waeBarValue[];
double waeBarColor[];
double waeExplosion[];
double waeDeadZone[];
double keltnerColor[];
double tdfiColor[];



//Functions global variables
static datetime Old_Time;
datetime New_Time[1];
bool IsNewBar=false;
bool NewBar=false;

//HMA variables
int trendPeriod      = 14;
double trendDivisor     = 1.0;
ENUM_APPLIED_PRICE HMA_Applied_Price = PRICE_CLOSE;
ENUM_TIMEFRAMES keltTime = PERIOD_CURRENT;


//WAE variables
int FastMA = 20;       // Period of the fast MACD moving average
int SlowMA = 40;       // Period of the slow MACD moving average
int BBandPeriod=20;        // Bollinger period
double BBandDeviation=2.0; // Number of Bollinger deviations
int  Sensitive=70;
int  DeadZone=60;
int  ExplosivePower=80;
int  TrendingPower=150;
bool AlertWindows=false;
int  AlertCounts=2;
bool AlertLongTrade=false;
bool AlertShortTrade=false;
bool AlertExitLongTrade=false;
bool AlertExitShortTrade=false;


enum enPrices
{
   pr_close,      // Close
   pr_open,       // Open
   pr_high,       // High
   pr_low,        // Low
   pr_median,     // Median
   pr_typical,    // Typical
   pr_weighted,   // Weighted
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage   // Heiken ashi average
};

enum enMaModes
{
   ma_Simple,  // Simple moving average
   ma_Expo,
   ma_ema     // Exponential moving average
};
enum enMaVisble
{
   mv_Visible,    // Middle line visible
   mv_NotVisible  // Middle line not visible
};

enum enCandleMode
{
   cm_None,   // Do not draw candles nor bars
   cm_Bars,   // Draw as bars
   cm_Candles // Draw as candles
};

enum enAtrMode
{
   atr_Rng,   // Calculate using range
   atr_Atr    // Calculate using ATR
};
//Keltner variables
ENUM_TIMEFRAMES    K_TimeFrame       = PERIOD_CURRENT; // Time frame
int                K_MAPeriod        = 50;             // Moving average period
enMaModes          K_MAMethod        = ma_Expo;      // Moving average type
enMaVisble         K_MAVisible       = mv_Visible;     // Midlle line visible ?
enPrices           K_Price           = pr_haclose;     // Moving average price 
color              K_MaColorUp       = clrDeepSkyBlue; // Color for slope up
color              K_MaColorDown     = clrPaleVioletRed; // Color for slope down
int                K_AtrPeriod       = 20;             // Range period
double             K_AtrMultiplier   = 3.0;            // Range multiplier
enAtrMode             K_AtrMode         = atr_Rng;        // Range calculating mode 
enCandleMode             K_ViewBars        = cm_None;        // View bars as :
bool               K_Interpolate     = true;           // Interpolate mtf data


//TDFI values


int       TDFI_trendPeriod  = 20;      // Trend period
int       TDFI_smoothPeriod = 1;       // Smoothing period
enMaModes TDFI_smoothType   = ma_ema;  // Smoothing type
double    TDFI_TriggerUp    =  0.005;   // Trigger up level
double    TDFI_TriggerDown  = -0.005;   // Trigger down level

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---Get Handle for FastMA
//FastMAHandle = iMA(_Symbol,_Period,FastMovingAverage,0,MODE_EMA,PRICE_CLOSE);
//SlowMAHandle = iMA(_Symbol,_Period,SlowMovingAverage,0,MODE_SMA,PRICE_CLOSE);
//handle_HMA_Custom = iCustom(NULL,PERIOD_CURRENT,"HMA",trendPeriod,trendDivisor,HMA_Applied_Price);
handle_WAE_Custom = iCustom(NULL,PERIOD_CURRENT,"WAE",FastMA,SlowMA,BBandPeriod,BBandDeviation,Sensitive,DeadZone,ExplosivePower,TrendingPower);
handle_KELTNER_Custom = iCustom(NULL,PERIOD_CURRENT,"KELTNER",K_TimeFrame,K_MAPeriod,K_MAMethod,K_MAVisible,K_Price,K_MaColorUp,K_MaColorDown,K_AtrPeriod,K_AtrMultiplier,K_AtrMode,K_ViewBars,K_Interpolate);
handle_TDFI_Custom = iCustom(NULL,PERIOD_CURRENT,"TDFI",TDFI_trendPeriod,TDFI_smoothPeriod,TDFI_smoothType,TDFI_TriggerUp,TDFI_TriggerDown);
   if(handle_KELTNER_Custom < 0 || handle_TDFI_Custom < 0 || handle_WAE_Custom < 0) //FastMAHandle<0 || SlowMAHandle<0 || handle_HMA_Custom < 0 || handle_WAE_Custom < 0 || 
   {
      Alert("Error creating handles for indicators: ", GetLastError());
      return(INIT_FAILED);
   }
   
   if(!atr.Create(_Symbol,_Period,14))
   {
      Alert("Error getting ATR", GetLastError());
      return(INIT_FAILED);
   }
   ZeroMemory(mrequest);     // Initialization of mrequest structure
      
   // the rates arrays
   ArraySetAsSeries(mrate,true);   
   //ArraySetAsSeries(maFastVal,true);
   //ArraySetAsSeries(maSlowVal,true);   
   //ArraySetAsSeries(hmaValData,true);
   //ArraySetAsSeries(hmaValColor,true);
   ArraySetAsSeries(waeBarValue,true);
   ArraySetAsSeries(waeBarColor,true);
   ArraySetAsSeries(waeExplosion,true);
   ArraySetAsSeries(waeDeadZone,true);
   ArraySetAsSeries(keltnerColor,true);
   ArraySetAsSeries(tdfiColor,true);
      
   return(INIT_SUCCEEDED);
   
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---Deinitialize indicators
   //IndicatorRelease(FastMAHandle);
   //IndicatorRelease(SlowMAHandle);
   //IndicatorRelease(handle_HMA_Custom);
   IndicatorRelease(handle_WAE_Custom);
   IndicatorRelease(handle_KELTNER_Custom);
   IndicatorRelease(handle_TDFI_Custom);
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  
  
   int _OrdersTotal = OrdersTotal();
   int _PositionTotal = PositionsTotal();
   atr.Refresh();

      //--- Get the last price quote using the MQL5 MqlTick Structure
      if(!SymbolInfoTick(_Symbol,latest_price))
        {
         Alert("Error getting the latest price quote - error:",GetLastError(),"!!");
         return;
        }
      
      //--- Get the details of the latest 3 bars
      if(CopyRates(_Symbol,_Period,0,3,mrate)<0)
        {
         Alert("Error copying rates/history data - error:",GetLastError(),"!!");
         return;
        }
      
      //--- Copy the new values of our indicators to buffers (arrays) using the handle
      //if(CopyBuffer(SlowMAHandle,0,0,3,maSlowVal)<0)
      //  {
      //   Alert("Error copying MA Slow to Buffers - error:",GetLastError(),"!!");
      //   return;
      //  }
      //if(CopyBuffer(FastMAHandle,0,0,3,maFastVal)<0)
      //  {
      //   Alert("Error copying MA Fast to buffer - error:",GetLastError());
      //   return;
      //  }
      
      int iint = 60;
      double doble;
      double current_spread;
      double current_atr;
      double current_ask;
      double current_bid;
      
      
      current_ask = latest_price.ask;
      current_bid = latest_price.bid;
      doble = NormalizeDouble(iint*_Point,_Digits);
      
      
      //calculate stop loss based on 1.5x the ATR
      current_spread = mrate[0].spread * _Point;
      current_atr = NormalizeDouble(atr.Main(1),_Digits);

      
      
      //HMA_CheckTradeSignal0();
      iWAE_GetValue();
      iKeltner_GetValue();
      iTDFI_GetValue();
      
      p_close = mrate[1].close;  // bar 1 close price
      p_open = mrate[1].open;
      p_high = mrate[1].high;
      p_low = mrate[1].low;           
      p_openclose_diff = p_close - p_open;

      //Print(keltnerColor[1]," ",tdfiColor[1]);
      
      //Kelter color - 0.0 is blue/green and 1.0 is red
      //TDFI color - 0.0 is gray and 1.0 is orange and 2.0 is blue
      //wae 1.0 is green and 2.0 is red
            
      
      //Check if there is an existing trade
      if(_PositionTotal < 1)
      {
  
            STP = (NormalizeDouble(atr.Main(1),_Digits)*2.0) + current_spread;
            TKP = (NormalizeDouble(atr.Main(1),_Digits)*2.0) + current_spread;            
            
               
               
         
            //check Signals if agree with entering a but trade
            if(BuySignals())
            {
               SendBuyTrade();
            }
            
            
            //check Signals if agree with entering a but trade
            else if(SellSignals())
            {
               SendSellTrade();
            }
            
            else
            {
               //Print("Conditions doesnt agree");
               return;
            }
         
         
      }
   
   
   
      //If there is an existing trade, manage this trade
      else if(_PositionTotal > 0)
      {
         //Print("There is an open trade - "," Positions total: ", _PositionTotal);
         ManageOpenPosition(current_spread,current_atr, current_ask, current_bid);
      }
   
   
  }
//+------------------------------------------------------------------+





//Functions!!!

bool BuySignals()
{
   //Declare Buy conditions
   //bool Buy_Condition_1 = (hmaValColor[0] == 1.0); // Fast MA Increasing upwards
   //bool Buy_Condition_2 = (p_close > p_open); // Slow MA Increasing upwards
   //bool Buy_Condition_3 = (p_close > maSlowVal[1]);         // previuos price closed above Fast MA
   //bool Buy_Condition_4 = (maFastVal[1] > maSlowVal[1]);          // FastMA is higher than Slow MA   
   bool Buy_Condition_5 = false;
   //bool Buy_Condition_6 = waeBarColor[1] == 1.0;         
   //bool Buy_Condition_7 = waeBarValue[1] > waeExplosion[1];
   //bool Buy_Condition_8 = waeBarValue[1] > waeDeadZone[1];
   
   if(keltnerColor[1] == 0.0 && tdfiColor[1] == 2.0 && waeBarColor[1] == 1.0 && waeBarValue[1] >= waeExplosion[1]) // && waeBarColor[1] == 2.0 && waeBarValue[1] > waeExplosion[1]
   {
      //if(p_openclose_diff < 0.00050)
      //{
         return true;
      //}
   }
   else
   {
      return false;
   }
   

}

bool SellSignals()
{
   //Declare Sell conditions
   //bool Sell_Condition_1 = (hmaValColor[0] == 2.0); // Fast MA Increasing downwards
   //bool Sell_Condition_2 = (p_close < p_open); // Slow MA Increasing downwards
   //bool Sell_Condition_3 = (p_close < maSlowVal[1]);         // previuos price closed below Fast MA
   //bool Sell_Condition_4 = (maFastVal[1] < maSlowVal[1]);          // FastMA is low than Slow MA               
   bool Sell_Condition_5 = false;
   //bool Sell_Condition_6 = waeBarColor[1] == 2.0;
   //bool Sell_Condition_7 = waeBarValue[1] > waeExplosion[1];
   //bool Sell_Condition_8 = waeBarValue[1] > waeDeadZone[1];

   if(keltnerColor[1] == 1.0 && tdfiColor[1] == 1.0 && waeBarColor[1] == 2.0 && waeBarValue[1] >= waeExplosion[1]) //  && waeBarColor[1] == 1.0 && waeBarValue[1] > waeExplosion[1]
   {
      //if(p_openclose_diff > 0.00050)
      return true;
   }            
   else
   {
      return false;
   }
      
}

void SendBuyTrade()
{
                  mrequest.action = TRADE_ACTION_DEAL;                                // immediate order execution
                  mrequest.price = NormalizeDouble(latest_price.ask,_Digits);          // latest ask price
                  mrequest.sl = latest_price.ask - STP; // Stop Loss
                  //mrequest.tp = latest_price.ask + TKP; // Take Profit
                  mrequest.symbol = _Symbol;                                         // currency pair
                  mrequest.volume = Lot;                                            // number of lots to trade
                  mrequest.magic = EA_Magic;                                        // Order Magic Number
                  mrequest.type = ORDER_TYPE_BUY;                                     // Buy Order
                  mrequest.type_filling = ORDER_FILLING_FOK;                          // Order execution type
                  mrequest.deviation=100;                                            // Deviation from current price
                  //--- send order
                  OrderSend(mrequest,mresult);
                     if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
                    {
                     Print("A Buy order has been successfully placed with Ticket#:",mresult.order,"!!");
                    }
                  else
                    {
                     Print("The Buy order request could not be completed -error:",GetLastError());
                     ResetLastError();
                     return;
                    }               
}
void SendSellTrade()
{

                  mrequest.action = TRADE_ACTION_DEAL;                                // immediate order execution
                  mrequest.price = NormalizeDouble(latest_price.bid,_Digits);          // latest ask price
                  mrequest.sl = latest_price.bid + STP; // Stop Loss
                  //mrequest.tp = latest_price.bid - TKP; // Take Profit
                  mrequest.symbol = _Symbol;                                         // currency pair
                  mrequest.volume = Lot;                                            // number of lots to trade
                  mrequest.magic = EA_Magic;                                        // Order Magic Number
                  mrequest.type = ORDER_TYPE_SELL;                                     // Buy Order
                  mrequest.type_filling = ORDER_FILLING_FOK;                          // Order execution type
                  mrequest.deviation=100;                                            // Deviation from current price
                  //--- send order
                  OrderSend(mrequest,mresult);
                     if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
                     {
                     Print("A Sell order has been successfully placed with Ticket#:",mresult.order,"!!");
                     }
                     else
                     {Print
                        ("The Sell order request could not be completed -error:",GetLastError());
                        ResetLastError();
                        return;
                     }
}

void ManageOpenPosition(double current_spread, double current_atr, double current_ask, double current_bid)
{

         //Get the curren open position
         int _PositionTicket = PositionGetTicket(0);
         //double Shadow_TakeProfit = (NormalizeDouble(atr.Main(1),_Digits)*2.0) + current_spread;
         
         
         //Manage the open position
         int _PositionType = Trade_position.PositionType();
         double _PositionPrice = Trade_position.PriceOpen();
         string _PositionDescription = Trade_position.TypeDescription();
         double _PositionSize = Trade_position.Volume();
         double _LastPrice = Trade_symbolinfo.Last();
         double _CurrentStopLoss = PositionGetDouble(POSITION_SL);
         double _CurrentTakeProfit = PositionGetDouble(POSITION_TP);
         double New_STP_target = NormalizeDouble(((current_atr*2.0) + current_spread),_Digits);
         double New_TKP_target = (current_atr*2.0)+ current_spread;
            
         //Print("Current SL: ",_CurrentStopLoss," New SL: ",New_STP);
         //--- Do we have positions opened already?
         //bool Buy_opened=false;  // variable to hold the result of Buy opened position
         //bool Sell_opened=false; // variable to hold the result of Sell opened position 
         
         
         //Print(_PositionSize);
           
            //Buy type of open position
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            {
               double New_STP = current_ask - New_STP_target;
               double New_TKP = current_ask + New_TKP_target;
                              
               if(tdfiColor[1] == 0.0 && tdfiColor[0] == 1.0) // || waeBarValue[2] > waeExplosion[2])            
               {
                  Trade_trade.PositionClose(_PositionTicket,0);
                  
               }
               else if(_CurrentStopLoss < New_STP)
               { 

                  Trade_trade.PositionModify(_PositionTicket,New_STP,New_TKP);                   
               //Print("ShadowTP ",_PositionPrice + TKP);
               
//               if(current_bid >= _PositionPrice + TKP)
//               {
//                  
//                  Print("Shadow TP hit");
//                  
//                  Trade_trade.PositionClosePartial(_PositionTicket,_PositionSize / 2.0);
//                  
//               }
//               
                 

               }
               
               
            }
            else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            {
               double New_STP = current_ask + New_STP_target;
               double New_TKP = current_ask - New_TKP_target;            
               if(tdfiColor[1] == 1.0 && tdfiColor[0] == 0.0) // || waeBarValue[2] > waeExplosion[2])            
               {
                  Trade_trade.PositionClose(_PositionTicket,0);
                  
               }
               else if(_CurrentStopLoss > New_STP)
               {
                  
                  Trade_trade.PositionModify(_PositionTicket,New_STP,New_TKP);                 
               }
//               Print("ShadowTP hit ",_PositionPrice - TKP);

//               if(current_ask <= _PositionPrice - TKP)
//               {
//                  
//                  Print("Shadow TP hit");                  
//                  Trade_trade.PositionClosePartial(_PositionTicket,_PositionSize / 2.0);
//                  
//               }
               
            }

}

//iCustom function

//bool HMA_CheckTradeSignal0()
//{
//   int start_pos=0,count=10;
//   if(!HMAGetArray(handle_HMA_Custom,0,start_pos,count,hmaValData) || 
//      !HMAGetArray(handle_HMA_Custom,1,start_pos,count,hmaValColor))
//   {
//      return false;
//   }
//   //Print("HMA Data: ",hmaValData[0]);
//   //Print("HMA Color Index: ",hmaValColor[0]);
//   return true;
//   
//   //Print("HMA Buffer 0: ",iCustom(NULL,PERIOD_CURRENT,"HMA",trendPeriod,trendDivisor,HMA_Applied_Price));
//   //Print("HMA Buffer 1: ",iCustom(NULL,PERIOD_CURRENT,"HMA",trendPeriod,trendDivisor,HMA_Applied_Price));   
//   //Print("KELTNER Buffer 0: ",iCustom(NULL,PERIOD_CURRENT,"KELTNER",keltTime));
//
//}


bool iWAE_GetValue()
{

   int start_pos=0,count=10;
   if(!HMAGetArray(handle_WAE_Custom,0,start_pos,count,waeBarValue) || 
      !HMAGetArray(handle_WAE_Custom,1,start_pos,count,waeBarColor) ||
      !HMAGetArray(handle_WAE_Custom,2,start_pos,count,waeExplosion) ||
      !HMAGetArray(handle_WAE_Custom,2,start_pos,count,waeDeadZone) )
   {
      return false;
   }
   //Print("HistoGramBarHeight WAE Signal 0: ",MathAbs(waeSignal0[1]));
   //Print("HistoGramBarColor  WAE Signal 1: ",waeSignal1[1]);
   //Print("WAE Signal 2: ",MathAbs(waeSignal2[1]));
   //Print("WAE Signal 3: ",waeSignal3[1]);
   return true;
}

bool iKeltner_GetValue()
{

   int start_pos=0,count=10;
   if(!HMAGetArray(handle_KELTNER_Custom,1,start_pos,count,keltnerColor))
   {
      return false;
   }
   //Print("HistoGramBarHeight WAE Signal 0: ",MathAbs(waeSignal0[1]));
   //Print("HistoGramBarColor  WAE Signal 1: ",waeSignal1[1]);
   //Print("WAE Signal 2: ",MathAbs(waeSignal2[1]));
   //Print("WAE Signal 3: ",waeSignal3[1]);
   return true;
}

bool iTDFI_GetValue()
{

   int start_pos=0,count=10;
   if(!HMAGetArray(handle_TDFI_Custom,3,start_pos,count,tdfiColor))
   {
      return false;
   }
   //Print("HistoGramBarHeight WAE Signal 0: ",MathAbs(waeSignal0[1]));
   //Print("HistoGramBarColor  WAE Signal 1: ",waeSignal1[1]);
   //Print("WAE Signal 2: ",MathAbs(waeSignal2[1]));
   //Print("WAE Signal 3: ",waeSignal3[1]);
   return true;
}

bool HMAGetArray(const int handle,const int buffer,const int start_pos,const int count,double &arr_buffer[])
{
   bool result=true;
   if(!ArrayIsDynamic(arr_buffer))
     {
      Print("This a no dynamic array!");
      return(false);
     }
   ArrayFree(arr_buffer);
   //--- reset error code 
   ResetLastError();
   //--- fill a part of the iBands array with values from the indicator buffer
   int copied=CopyBuffer(handle,buffer,start_pos,count,arr_buffer);
   if(copied!=count)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(false);
     }
   return(result);

}

bool CheckIfNewBar(){

// copying the last bar time to the element New_Time[0]
   int copied=CopyTime(_Symbol,_Period,0,1,New_Time);
   if(copied>0) // ok, the data has been copied successfully
     {
      if(Old_Time!=New_Time[0]) // if old time isn't equal to new bar time
        {
         IsNewBar=true;   // if it isn't a first call, the new bar has appeared
         if(MQL5InfoInteger(MQL5_DEBUGGING)) Print("We have new bar here ",New_Time[0]," old time was ",Old_Time);
         Old_Time=New_Time[0];            // saving bar time
         return true;
        }
      else{
         return false;
      }
     }
   else
     {
      Alert("Error in copying historical times data, error =",GetLastError());
      ResetLastError();
      return false;
     }

}

