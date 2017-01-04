//+------------------------------------------------------------------+
//|                                                         MACD.mqh |
//|                            Copyright 2016, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+
#property strict
#include <kenorb\BasicTrade.mqh>
//---
#define MACD_BUFFERS 2
#define MACD_VALUES  3
//---
#define MACD_MAIN    0
#define MACD_SIGNAL  1
//+------------------------------------------------------------------+
//|   CiMACDTrade                                                    |
//+------------------------------------------------------------------+
class CiMACDTrade : public CBasicTrade
  {
private:
   string            m_symbol;
   uint              m_fast_period;
   uint              m_slow_period;
   uint              m_signal_period;
   ENUM_APPLIED_PRICE m_price;
   uint              m_shift;

   int               m_handles[TFS];
   double            m_val[MACD_BUFFERS][TFS][MACD_VALUES];
   int               m_last_error;

   //+------------------------------------------------------------------+
   bool  Update(const ENUM_TIMEFRAMES _tf=PERIOD_CURRENT)
     {
      int index=TimeframeToIndex(_tf);

#ifdef __MQL4__
      for(int i=0;i<MACD_BUFFERS;i++)
         for(int k=0;k<MACD_VALUES;k++)
           {
            m_val[i][index][k]=iMACD(NULL,
                                     _tf,
                                     m_fast_period,
                                     m_slow_period,
                                     m_signal_period,
                                     m_price,
                                     i,
                                     k);
           }
      return(true);
#endif

#ifdef __MQL5__
      double array[];
      for(int i=0;i<MACD_BUFFERS;i++)
        {
         if(CopyBuffer(m_handles[index],i,m_shift,MACD_VALUES,array)!=MACD_VALUES)
            return(false);
         for(int k=0;k<MACD_VALUES;k++)
            m_val[i][index][k]=array[MACD_VALUES-1-k];
        }
      return(true);
#endif

      return(false);
     }

public:

   //+------------------------------------------------------------------+
   void  CiMACDTrade()
     {
      m_last_error=0;
      ArrayInitialize(m_handles,INVALID_HANDLE);
      m_fast_period=12;
      m_slow_period=26;
      m_signal_period=9;
      m_price=PRICE_CLOSE;
     }

   //+------------------------------------------------------------------+
   bool  SetParams(const string symbol,
                   const int fast_period,
                   const int slow_period,
                   const int signal_period,
                   const ENUM_APPLIED_PRICE price,
                   const int shift)
     {
      m_symbol=symbol;
      m_fast_period=fmax(1,fast_period);
      m_slow_period=fmax(1,slow_period);
      m_fast_period=fmax(1,signal_period);
      m_price=price;
      m_shift=fmax(0,shift);

#ifdef __MQL5__
      for(int i=0;i<TFS;i++)
        {
         m_handles[i]=iMACD(m_symbol,
                            tf[i],
                            m_fast_period,
                            m_slow_period,
                            m_signal_period,
                            m_price
                            );
         if(m_handles[i]==INVALID_HANDLE)
            return(false);
        }
#endif
      return(true);
     }
   //+------------------------------------------------------------------+
   bool              Signal(const ENUM_TRADE_DIRECTION _cmd,const ENUM_TIMEFRAMES _tf,int _open_method,const int open_level)
     {

      if(!Update(_tf))
         return(false);

      //--- detect 'one of methods'
      bool one_of_methods=false;
      if(_open_method<0)
         one_of_methods=true;
      _open_method=fabs(_open_method);

      //---
      int index=TimeframeToIndex(_tf);
      double level=open_level*_Point;

      //---
      int result[OPEN_METHODS];
      ArrayInitialize(result,-1);

      for(int i=0; i<OPEN_METHODS; i++)
        {
         //---
         if(_cmd==TRADE_BUY)
           {
            switch(_open_method&(int)pow(2,i))
              {
               case OPEN_METHOD1:
                  result[i]=(m_val[MACD_MAIN][index][CUR]<0.0 &&
                             m_val[MACD_MAIN][index][PREV]<m_val[MACD_SIGNAL][index][PREV] &&
                             m_val[MACD_MAIN][index][CUR]>m_val[MACD_SIGNAL][index][CUR]+level);
               break;
               //---
               case OPEN_METHOD2:
                  result[i]=(m_val[MACD_MAIN][index][PREV]<0 &&
                             m_val[MACD_MAIN][index][CUR]>=0);
               break;

               case OPEN_METHOD3: result[i]=false; break;
               case OPEN_METHOD4: result[i]=false; break;
               case OPEN_METHOD5: result[i]=false; break;
               case OPEN_METHOD6: result[i]=false; break;
               case OPEN_METHOD7: result[i]=false; break;
               case OPEN_METHOD8: result[i]=false; break;

              }
           }

         //---
         if(_cmd==TRADE_SELL)
           {
            switch(_open_method&(int)pow(2,i))
              {
               case OPEN_METHOD1:
                  result[i]=(m_val[MACD_MAIN][index][CUR]>0.0 &&
                             m_val[MACD_MAIN][index][PREV]>m_val[MACD_SIGNAL][index][PREV] &&
                             m_val[MACD_MAIN][index][CUR]<m_val[MACD_SIGNAL][index][CUR]-level);
               break;

               //---
               case OPEN_METHOD2:
                  result[i]=(m_val[MACD_MAIN][index][PREV]>0 &&
                             m_val[MACD_MAIN][index][CUR]<=0);
               break;

               //---
               case OPEN_METHOD3: result[i]=false; break;
               case OPEN_METHOD4: result[i]=false; break;
               case OPEN_METHOD5: result[i]=false; break;
               case OPEN_METHOD6: result[i]=false; break;
               case OPEN_METHOD7: result[i]=false; break;
               case OPEN_METHOD8: result[i]=false; break;

              }
           }
        }
      //--- calc result
      bool res_value=false;
      for(int i=0; i<OPEN_METHODS; i++)
        {
         //--- true
         if(result[i]==1)
           {
            res_value=true;

            //--- OR logic
            if(one_of_methods)
               break;
           }

         //--- false
         if(result[i]==0)
           {
            res_value=false;

            //--- AND logic
            if(!one_of_methods)
               break;
           }
        }
      //--- done
      return(res_value);
     }
  };
//+------------------------------------------------------------------+
