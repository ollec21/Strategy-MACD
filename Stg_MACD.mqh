/**
 * @file
 * Implements MACD strategy based on the Moving Averages Convergence/Divergence indicator.
 */

// User input params.
INPUT int MACD_Period_Fast = 23;                            // Period Fast
INPUT int MACD_Period_Slow = 21;                            // Period Slow
INPUT int MACD_Period_Signal = 10;                          // Period for signal
INPUT ENUM_APPLIED_PRICE MACD_Applied_Price = PRICE_CLOSE;  // Applied Price
INPUT int MACD_Shift = 3;                                   // Shift
INPUT int MACD_SignalOpenMethod = -26;                      // Signal open method (-31-31)
INPUT float MACD_SignalOpenLevel = 0.1f;                    // Signal open level
INPUT int MACD_SignalOpenFilterMethod = 0;                  // Signal open filter method
INPUT int MACD_SignalOpenBoostMethod = 0;                   // Signal open boost method
INPUT int MACD_SignalCloseMethod = -26;                     // Signal close method (-31-31)
INPUT float MACD_SignalCloseLevel = 0.1f;                   // Signal close level
INPUT int MACD_PriceLimitMethod = 0;                        // Price limit method
INPUT float MACD_PriceLimitLevel = 0;                       // Price limit level
INPUT float MACD_MaxSpread = 6.0;                           // Max spread to trade (pips)

// Includes.
#include <EA31337-classes/Indicators/Indi_MACD.mqh>
#include <EA31337-classes/Strategy.mqh>

// Struct to define strategy parameters to override.
struct Stg_MACD_Params : StgParams {
  int MACD_Period_Fast;
  int MACD_Period_Slow;
  int MACD_Period_Signal;
  ENUM_APPLIED_PRICE MACD_Applied_Price;
  int MACD_Shift;
  int MACD_SignalOpenMethod;
  float MACD_SignalOpenLevel;
  int MACD_SignalOpenFilterMethod;
  int MACD_SignalOpenBoostMethod;
  int MACD_SignalCloseMethod;
  float MACD_SignalCloseLevel;
  int MACD_PriceLimitMethod;
  float MACD_PriceLimitLevel;
  float MACD_MaxSpread;

  // Constructor: Set default param values.
  Stg_MACD_Params()
      : MACD_Period_Fast(::MACD_Period_Fast),
        MACD_Period_Slow(::MACD_Period_Slow),
        MACD_Period_Signal(::MACD_Period_Signal),
        MACD_Applied_Price(::MACD_Applied_Price),
        MACD_Shift(::MACD_Shift),
        MACD_SignalOpenMethod(::MACD_SignalOpenMethod),
        MACD_SignalOpenLevel(::MACD_SignalOpenLevel),
        MACD_SignalOpenFilterMethod(::MACD_SignalOpenFilterMethod),
        MACD_SignalOpenBoostMethod(::MACD_SignalOpenBoostMethod),
        MACD_SignalCloseMethod(::MACD_SignalCloseMethod),
        MACD_SignalCloseLevel(::MACD_SignalCloseLevel),
        MACD_PriceLimitMethod(::MACD_PriceLimitMethod),
        MACD_PriceLimitLevel(::MACD_PriceLimitLevel),
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
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Stg_MACD_Params>(_params, _tf, stg_macd_m1, stg_macd_m5, stg_macd_m15, stg_macd_m30, stg_macd_h1,
                                     stg_macd_h4, stg_macd_h4);
    }
    // Initialize strategy parameters.
    MACDParams macd_params(_params.MACD_Period_Fast, _params.MACD_Period_Slow, _params.MACD_Period_Signal,
                           _params.MACD_Applied_Price);
    macd_params.SetTf(_tf);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_MACD(macd_params), NULL, NULL);
    sparams.logger.Ptr().SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.MACD_SignalOpenMethod, _params.MACD_SignalOpenLevel, _params.MACD_SignalCloseMethod,
                       _params.MACD_SignalOpenFilterMethod, _params.MACD_SignalOpenBoostMethod,
                       _params.MACD_SignalCloseLevel);
    sparams.SetPriceLimits(_params.MACD_PriceLimitMethod, _params.MACD_PriceLimitLevel);
    sparams.SetMaxSpread(_params.MACD_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_MACD(sparams, "MACD");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0) {
    Indi_MACD *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    double _level_pips = _level * Chart().GetPipSize();
    if (_is_valid) {
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          // Buy: MACD rises above the signal line.
          _result = _indi[PPREV].value[LINE_MAIN] < 0 &&
                    _indi[CURR].value[LINE_MAIN] >
                        _indi[CURR].value[LINE_SIGNAL] + _level_pips;  // MACD rises above the signal line.
          if (_method != 0) {
            if (METHOD(_method, 0)) _result &= _indi[PPREV].value[LINE_MAIN] < _indi[PPREV].value[LINE_SIGNAL];
            // Buy: crossing 0 upwards.
            if (METHOD(_method, 1)) _result &= _indi[CURR].value[LINE_MAIN] > 0;
          }
          break;
        case ORDER_TYPE_SELL:
          // Sell: MACD falls below the signal line.
          _result = _indi[PPREV].value[LINE_MAIN] > 0 &&
                    _indi[CURR].value[LINE_MAIN] >
                        _indi[CURR].value[LINE_SIGNAL] - _level_pips;  // MACD falls below the signal line.
          if (_method != 0) {
            if (METHOD(_method, 0)) _result &= _indi[PPREV].value[LINE_MAIN] > _indi[PPREV].value[LINE_SIGNAL];
            // Sell: crossing 0 downwards.
            if (METHOD(_method, 1)) _result &= _indi[CURR].value[LINE_MAIN] < 0;
          }
          break;
      }
    }
    return _result;
  }

  /**
   * Gets price limit value for profit take or stop loss.
   */
  float PriceLimit(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_MACD *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    if (_is_valid) {
      switch (_method) {
        case 0: {
          int _bar_count = (int)_level * (int)_indi.GetEmaFastPeriod();
          _result = _direction < 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
          break;
        }
        case 1: {
          int _bar_count = (int)_level * (int)_indi.GetEmaSlowPeriod();
          _result = _direction < 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
          break;
        }
        case 2: {
          int _bar_count = (int)_level * (int)_indi.GetSignalPeriod();
          _result = _direction < 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
          break;
        }
        case 3:
          _result = (_direction > 0 ? fmax(_indi[PPREV].value[LINE_MAIN], _indi[PPREV].value[LINE_SIGNAL])
                                    : fmin(_indi[PPREV].value[LINE_MAIN], _indi[PPREV].value[LINE_SIGNAL]));
          break;
      }
      _result += _trail * _direction;
    }
    return (float)_result;
  }
};
