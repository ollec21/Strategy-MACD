//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/**
 * @file
 * Implements MACD strategy based on the Moving Averages Convergence/Divergence indicator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_MACD.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT string __MACD_Parameters__ = "-- MACD strategy params --";  // >>> MACD <<<
INPUT int MACD_Active_Tf = 0;       // Activate timeframes (1-255, e.g. M1=1,M5=2,M15=4,M30=8,H1=16,H2=32...)
INPUT int MACD_Period_Fast = 23;    // Period Fast
INPUT int MACD_Period_Slow = 21;    // Period Slow
INPUT int MACD_Period_Signal = 10;  // Period for signal
INPUT ENUM_APPLIED_PRICE MACD_Applied_Price = PRICE_CLOSE;  // Applied Price
INPUT int MACD_Shift = 3;                                   // Shift
INPUT ENUM_TRAIL_TYPE MACD_TrailingStopMethod = -1;         // Trail stop method
INPUT ENUM_TRAIL_TYPE MACD_TrailingProfitMethod = -19;      // Trail profit method
INPUT double MACD_SignalOpenLevel = 0.1;                    // Signal open level
INPUT int MACD1_SignalBaseMethod = -26;                     // Signal base method (-31-31)
INPUT int MACD1_OpenCondition1 = 874;                       // Open condition 1 (0-1023)
INPUT int MACD1_OpenCondition2 = 0;                         // Open condition 2 (0-1023)
INPUT ENUM_MARKET_EVENT MACD1_CloseCondition = 1;           // Close condition for M1
INPUT double MACD_MaxSpread = 6.0;                          // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_MACD_Params : Stg_Params {
  unsigned int MACD_Period;
  ENUM_APPLIED_PRICE MACD_Applied_Price;
  int MACD_Shift;
  ENUM_TRAIL_TYPE MACD_TrailingStopMethod;
  ENUM_TRAIL_TYPE MACD_TrailingProfitMethod;
  double MACD_SignalOpenLevel;
  long MACD_SignalBaseMethod;
  long MACD_SignalOpenMethod1;
  long MACD_SignalOpenMethod2;
  double MACD_SignalCloseLevel;
  ENUM_MARKET_EVENT MACD_SignalCloseMethod1;
  ENUM_MARKET_EVENT MACD_SignalCloseMethod2;
  double MACD_MaxSpread;

  // Constructor: Set default param values.
  Stg_MACD_Params()
      : MACD_Period(::MACD_Period),
        MACD_Applied_Price(::MACD_Applied_Price),
        MACD_Shift(::MACD_Shift),
        MACD_TrailingStopMethod(::MACD_TrailingStopMethod),
        MACD_TrailingProfitMethod(::MACD_TrailingProfitMethod),
        MACD_SignalOpenLevel(::MACD_SignalOpenLevel),
        MACD_SignalBaseMethod(::MACD_SignalBaseMethod),
        MACD_SignalOpenMethod1(::MACD_SignalOpenMethod1),
        MACD_SignalOpenMethod2(::MACD_SignalOpenMethod2),
        MACD_SignalCloseLevel(::MACD_SignalCloseLevel),
        MACD_SignalCloseMethod1(::MACD_SignalCloseMethod1),
        MACD_SignalCloseMethod2(::MACD_SignalCloseMethod2),
        MACD_MaxSpread(::MACD_MaxSpread) {}
};

// Loads pair specific param values.
#include "sets/EURUSD_H1.h"
#include "sets/EURUSD_H4.h"
#include "sets/EURUSD_M1.h"
#include "sets/EURUSD_M15.h"
#include "sets/EURUSD_M30.h"
#include "sets/EURUSD_M5.h"

class Stg_MACD : public Strategy {
 public:
  Stg_MACD(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_MACD *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Stg_MACD_Params _params;
    switch (_tf) {
      case PERIOD_M1: {
        Stg_MACD_EURUSD_M1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M5: {
        Stg_MACD_EURUSD_M5_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M15: {
        Stg_MACD_EURUSD_M15_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M30: {
        Stg_MACD_EURUSD_M30_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H1: {
        Stg_MACD_EURUSD_H1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H4: {
        Stg_MACD_EURUSD_H4_Params _new_params;
        _params = _new_params;
      }
    }
    // Initialize strategy parameters.
    ChartParams cparams(_tf);
    MACD_Params adx_params(_params.MACD_Period, _params.MACD_Applied_Price);
    IndicatorParams adx_iparams(10, INDI_MACD);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_MACD(adx_params, adx_iparams, cparams), NULL, NULL);
    sparams.logger.SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.MACD_SignalBaseMethod, _params.MACD_SignalOpenMethod1, _params.MACD_SignalOpenMethod2,
                       _params.MACD_SignalCloseMethod1, _params.MACD_SignalCloseMethod2, _params.MACD_SignalOpenLevel,
                       _params.MACD_SignalCloseLevel);
    sparams.SetStops(_params.MACD_TrailingProfitMethod, _params.MACD_TrailingStopMethod);
    sparams.SetMaxSpread(_params.MACD_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_MACD(sparams, "MACD");
    return _strat;
  }

  /**
   * Check if MACD indicator is on buy.
   *
   * @param
   *   _cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   _signal_method (int) - signal method to use by using bitwise AND operation
   *   _signal_level1 (double) - signal level to consider the signal
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    bool _result = false;
    double macd_0_main = ((Indi_MACD *)this.Data()).GetValue(LINE_MAIN, 0);
    double macd_0_signal = ((Indi_MACD *)this.Data()).GetValue(LINE_SIGNAL, 0);
    double macd_1_main = ((Indi_MACD *)this.Data()).GetValue(LINE_MAIN, 1);
    double macd_1_signal = ((Indi_MACD *)this.Data()).GetValue(LINE_SIGNAL, 1);
    double macd_2_main = ((Indi_MACD *)this.Data()).GetValue(LINE_MAIN, 2);
    double macd_2_signal = ((Indi_MACD *)this.Data()).GetValue(LINE_SIGNAL, 2);
    if (_signal_method == EMPTY) _signal_method = GetSignalBaseMethod();
    if (_signal_level1 == EMPTY) _signal_level1 = GetSignalLevel1();
    if (_signal_level2 == EMPTY) _signal_level2 = GetSignalLevel2();
    double gap = _signal_level1 * pip_size;
    switch (_cmd) {
      /* TODO:
            //20. MACD (1)
            //VERSION EXISTS, THAT THE SIGNAL TO BUY IS TRUE ONLY IF MACD<0, SIGNAL TO SELL - IF MACD>0
            //Buy: MACD rises above the signal line
            //Sell: MACD falls below the signal line
            if(iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,LINE_MAIN,1)<iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,LINE_SIGNAL,1)
            &&
         iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,LINE_MAIN,0)>=iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,LINE_SIGNAL,0))
            {f20=1;}
            if(iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,LINE_MAIN,1)>iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,LINE_SIGNAL,1)
            &&
         iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,LINE_MAIN,0)<=iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,LINE_SIGNAL,0))
            {f20=-1;}

            //21. MACD (2)
            //Buy: crossing 0 upwards
            //Sell: crossing 0 downwards
            if(iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,LINE_MAIN,1)<0&&iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,LINE_MAIN,0)>=0)
            {f21=1;}
            if(iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,LINE_MAIN,1)>0&&iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,LINE_MAIN,0)<=0)
            {f21=-1;}
      */
      case ORDER_TYPE_BUY:
        _result = macd_0_main > macd_0_signal + gap;  // MACD rises above the signal line.
        if (_signal_method != 0) {
          if (METHOD(_signal_method, 0)) _result &= macd_2_main < macd_2_signal;
          if (METHOD(_signal_method, 1)) _result &= macd_0_main >= 0;
          if (METHOD(_signal_method, 2)) _result &= macd_1_main < 0;
          if (METHOD(_signal_method, 3))
            _result &= ma_fast[this.Chart().TfToIndex()][CURR] > ma_fast[this.Chart().TfToIndex()][PREV];
          if (METHOD(_signal_method, 4))
            _result &= ma_fast[this.Chart().TfToIndex()][CURR] > ma_medium[this.Chart().TfToIndex()][CURR];
        }
        break;
      case ORDER_TYPE_SELL:
        _result = macd_0_main < macd_0_signal - gap;  // MACD falls below the signal line.
        if (_signal_method != 0) {
          if (METHOD(_signal_method, 0)) _result &= macd_2_main > macd_2_signal;
          if (METHOD(_signal_method, 1)) _result &= macd_0_main <= 0;
          if (METHOD(_signal_method, 2)) _result &= macd_1_main > 0;
          if (METHOD(_signal_method, 3))
            _result &= ma_fast[this.Chart().TfToIndex()][CURR] < ma_fast[this.Chart().TfToIndex()][PREV];
          if (METHOD(_signal_method, 4))
            _result &= ma_fast[this.Chart().TfToIndex()][CURR] < ma_medium[this.Chart().TfToIndex()][CURR];
        }
        break;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    if (_signal_level == EMPTY) _signal_level = GetSignalCloseLevel();
    return SignalOpen(Order::NegateOrderType(_cmd), _signal_method, _signal_level);
  }
};
