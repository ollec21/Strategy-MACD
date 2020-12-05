/**
 * @file
 * Implements MACD strategy based on the Moving Averages Convergence/Divergence indicator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_MACD.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT float MACD_LotSize = 0;               // Lot size
INPUT int MACD_SignalOpenMethod = -26;      // Signal open method (-31-31)
INPUT float MACD_SignalOpenLevel = 0.1f;    // Signal open level
INPUT int MACD_SignalOpenFilterMethod = 0;  // Signal open filter method
INPUT int MACD_SignalOpenBoostMethod = 0;   // Signal open boost method
INPUT int MACD_SignalCloseMethod = -26;     // Signal close method (-31-31)
INPUT float MACD_SignalCloseLevel = 0.1f;   // Signal close level
INPUT int MACD_PriceStopMethod = 0;         // Price stop method
INPUT float MACD_PriceStopLevel = 0;        // Price stop level
INPUT int MACD_TickFilterMethod = 0;        // Tick filter method
INPUT float MACD_MaxSpread = 6.0;           // Max spread to trade (pips)
INPUT int MACD_Shift = 3;                   // Shift
INPUT string __MACD_Indi_MACD_Parameters__ =
    "-- MACD strategy: MACD indicator params --";                // >>> MACD strategy: MACD indicator <<<
INPUT int Indi_MACD_Period_Fast = 23;                            // Period Fast
INPUT int Indi_MACD_Period_Slow = 21;                            // Period Slow
INPUT int Indi_MACD_Period_Signal = 10;                          // Period for signal
INPUT ENUM_APPLIED_PRICE Indi_MACD_Applied_Price = PRICE_CLOSE;  // Applied Price

// Structs.

// Defines struct with default user indicator values.
struct Indi_MACD_Params_Defaults : MACDParams {
  Indi_MACD_Params_Defaults()
      : MACDParams(::Indi_MACD_Period_Fast, ::Indi_MACD_Period_Slow, ::Indi_MACD_Period_Signal,
                   ::Indi_MACD_Applied_Price) {}
} indi_macd_defaults;

// Defines struct to store indicator parameter values.
struct Indi_MACD_Params : public MACDParams {
  // Struct constructors.
  void Indi_MACD_Params(MACDParams &_params, ENUM_TIMEFRAMES _tf) : MACDParams(_params, _tf) {}
};

// Defines struct with default user strategy values.
struct Stg_MACD_Params_Defaults : StgParams {
  Stg_MACD_Params_Defaults()
      : StgParams(::MACD_SignalOpenMethod, ::MACD_SignalOpenFilterMethod, ::MACD_SignalOpenLevel,
                  ::MACD_SignalOpenBoostMethod, ::MACD_SignalCloseMethod, ::MACD_SignalCloseLevel,
                  ::MACD_PriceStopMethod, ::MACD_PriceStopLevel, ::MACD_TickFilterMethod, ::MACD_MaxSpread,
                  ::MACD_Shift) {}
} stg_macd_defaults;

// Struct to define strategy parameters to override.
struct Stg_MACD_Params : StgParams {
  Indi_MACD_Params iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_MACD_Params(Indi_MACD_Params &_iparams, StgParams &_sparams)
      : iparams(indi_macd_defaults, _iparams.tf), sparams(stg_macd_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_MACD : public Strategy {
 public:
  Stg_MACD(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_MACD *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Indi_MACD_Params _indi_params(indi_macd_defaults, _tf);
    StgParams _stg_params(stg_macd_defaults);
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Indi_MACD_Params>(_indi_params, _tf, indi_macd_m1, indi_macd_m5, indi_macd_m15, indi_macd_m30,
                                      indi_macd_h1, indi_macd_h4, indi_macd_h8);
      SetParamsByTf<StgParams>(_stg_params, _tf, stg_macd_m1, stg_macd_m5, stg_macd_m15, stg_macd_m30, stg_macd_h1,
                               stg_macd_h4, stg_macd_h8);
    }
    // Initialize indicator.
    MACDParams macd_params(_indi_params);
    _stg_params.SetIndicator(new Indi_MACD(_indi_params));
    // Initialize strategy parameters.
    _stg_params.GetLog().SetLevel(_log_level);
    _stg_params.SetMagicNo(_magic_no);
    _stg_params.SetTf(_tf, _Symbol);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_MACD(_stg_params, "MACD");
    _stg_params.SetStops(_strat, _strat);
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_MACD *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    double _level_pips = _level * Chart().GetPipSize();
    if (_is_valid) {
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          // Buy: MACD rises above the signal line.
          _result =
              _indi[PPREV][LINE_MAIN] < 0 &&
              _indi[CURR][LINE_MAIN] > _indi[CURR][LINE_SIGNAL] + _level_pips;  // MACD rises above the signal line.
          if (_method != 0) {
            if (METHOD(_method, 0)) _result &= _indi[PPREV][LINE_MAIN] < _indi[PPREV][LINE_SIGNAL];
            // Buy: crossing 0 upwards.
            if (METHOD(_method, 1)) _result &= _indi[CURR][LINE_MAIN] > 0;
          }
          break;
        case ORDER_TYPE_SELL:
          // Sell: MACD falls below the signal line.
          _result =
              _indi[PPREV][LINE_MAIN] > 0 &&
              _indi[CURR][LINE_MAIN] > _indi[CURR][LINE_SIGNAL] - _level_pips;  // MACD falls below the signal line.
          if (_method != 0) {
            if (METHOD(_method, 0)) _result &= _indi[PPREV][LINE_MAIN] > _indi[PPREV][LINE_SIGNAL];
            // Sell: crossing 0 downwards.
            if (METHOD(_method, 1)) _result &= _indi[CURR][LINE_MAIN] < 0;
          }
          break;
      }
    }
    return _result;
  }

  /**
   * Gets price stop value for profit take or stop loss.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_MACD *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    if (_is_valid) {
      switch (_method) {
        case 1: {
          int _bar_count0 = (int)_level * (int)_indi.GetEmaFastPeriod();
          _result = _direction < 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count0))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count0));
          break;
        }
        case 2: {
          int _bar_count1 = (int)_level * (int)_indi.GetEmaSlowPeriod();
          _result = _direction < 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count1))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count1));
          break;
        }
        case 3: {
          int _bar_count2 = (int)_level * (int)_indi.GetSignalPeriod();
          _result = _direction < 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count2))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count2));
          break;
        }
        case 4:
          _result = (_direction > 0 ? fmax(_indi[PPREV][LINE_MAIN], _indi[PPREV][LINE_SIGNAL])
                                    : fmin(_indi[PPREV][LINE_MAIN], _indi[PPREV][LINE_SIGNAL]));
          break;
      }
      _result += _trail * _direction;
    }
    return (float)_result;
  }
};
