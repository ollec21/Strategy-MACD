//+------------------------------------------------------------------+
//|                 EA31337 - multi-strategy advanced trading robot. |
//|                       Copyright 2016-2017, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
    This file is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Properties.
#property strict

/**
 * @file
 * Implementation of MACD Strategy based on the Moving Averages Convergence/Divergence indicator.
 *
 * @docs
 * - https://docs.mql4.com/indicators/iMACD
 * - https://www.mql5.com/en/docs/indicators/iMACD
 */

// Includes.
#include "I_MACD.mqh"
#include <EA31337-classes\Strategy.mqh>

// User inputs.
#ifdef __input__ input #endif double MACD_SignalBaseLevel = 0;    // Signal base level
#ifdef __input__ input #endif int    MACD_SignalOpenMethod = -98; // Signal open method (-127-127)
#ifdef __input__ input #endif double MACD_SignalLevel = 1.2;      // Signal level
#ifdef __input__ input #endif string MACD_Override = "";          // Params to override

class S_MACD: public Strategy {
protected:

public:

  /**
   * Class constructor.
   */
  void S_MACD(StrategyParams &_params)
  {
  }

  /**
   * Initialize strategy.
   */
  bool Init() {
    bool initiated = true;
    IndicatorParams indi_params = { S_IND_MA };
    params.data = new I_MACD(indi_params);
    initiated &= IndicatorInfo().Update();
    initiated &= IndicatorInfo().GetValue(MODE_MAIN, CURR, (double) TYPE_DOUBLE) > 0;
    return initiated;
  }

  /**
   * Checks strategy trade signal.
   *
   * @param
   *   _cmd (int) - type of trade order command
   *   _base_method (int) - base signal method
   *   _open_method (int) - open signal method to use by using bitwise AND operation
   *   _level (double) - signal level to consider the signal
   */
  bool Signal(ENUM_ORDER_TYPE _cmd, int _base_method, int _open_method = 0, double _level = 0.0) {
    bool _signal = false;
    IndicatorInfo().Update();
    _level *= MarketInfo().GetPipSize();
    #define _MACD(type, index) IndicatorInfo().GetValue(type, index, (double) TYPE_DOUBLE)

    switch (_cmd) {
      /* TODO:
            //20. MACD (1)
            //VERSION EXISTS, THAT THE SIGNAL TO BUY IS TRUE ONLY IF MACD<0, SIGNAL TO SELL - IF MACD>0
            //Buy: MACD rises above the signal line
            //Sell: MACD falls below the signal line
            if(iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_MAIN,1)<iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_SIGNAL,1)
            && iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_MAIN,0)>=iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_SIGNAL,0))
            {f20=1;}
            if(iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_MAIN,1)>iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_SIGNAL,1)
            && iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_MAIN,0)<=iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_SIGNAL,0))
            {f20=-1;}

            //21. MACD (2)
            //Buy: crossing 0 upwards
            //Sell: crossing 0 downwards
            if(iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_MAIN,1)<0&&iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_MAIN,0)>=0)
            {f21=1;}
            if(iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_MAIN,1)>0&&iMACD(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,MODE_MAIN,0)<=0)
            {f21=-1;}
      */
      case OP_BUY:
        _signal = _MACD(MODE_MAIN, CURR) > _MACD(MODE_SIGNAL, CURR) + _level; // MACD rises above the signal line.
        if ((_open_method & OPEN_METHOD1) != 0) _signal &= _MACD(MODE_MAIN, FAR) < _MACD(MODE_SIGNAL, FAR);
        if ((_open_method & OPEN_METHOD2) != 0) _signal &= _MACD(MODE_MAIN, CURR) >= 0;
        if ((_open_method & OPEN_METHOD3) != 0) _signal &= _MACD(MODE_MAIN, PREV) < 0;
        // @todo
        // if ((_open_method & OPEN_METHOD4) != 0) _signal &= ma_fast[period, CURR) > ma_fast[period, PREV);
        // if ((_open_method & OPEN_METHOD5) != 0) _signal &= ma_fast[period, CURR) > ma_medium[period, CURR);
        break;
      case OP_SELL:
        _signal = _MACD(MODE_MAIN, CURR) < _MACD(MODE_SIGNAL, CURR) - _level; // MACD falls below the signal line.
        if ((_open_method & OPEN_METHOD1) != 0) _signal &= _MACD(MODE_MAIN, FAR) > _MACD(MODE_SIGNAL, FAR);
        if ((_open_method & OPEN_METHOD2) != 0) _signal &= _MACD(MODE_MAIN, CURR) <= 0;
        if ((_open_method & OPEN_METHOD3) != 0) _signal &= _MACD(MODE_MAIN, PREV) > 0;
        // @todo
        // if ((_open_method & OPEN_METHOD4) != 0) _signal &= ma_fast[period][CURR] < ma_fast[period][PREV];
        // if ((_open_method & OPEN_METHOD5) != 0) _signal &= ma_fast[period][CURR] < ma_medium[period][CURR];
        break;
    }
    // _signal &= _open_method <= 0 || Convert::ValueToOp(curr_trend) == cmd;
    #ifdef __debug__
      data.PrintData();
    #endif
    return _signal;
  }

};
