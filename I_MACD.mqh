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

/**
 * @file
 * Implements the Moving Average indicator.
 *
 * @docs
 * - https://docs.mql4.com/indicators/ima
 * - https://www.mql5.com/en/docs/indicators/ima
 */

// Properties.
#property strict

// Includes.
#include <EA31337-classes\Indicator.mqh>

// User inputs.
#ifdef __input__ input #endif string __MACD_Parameters__ = "-- Settings for the Moving Averages Convergence/Divergence indicator --"; // >>> MACD <<<
#ifdef __input__ input #endif int MACD_Period_Fast = 19; // Period Fast
#ifdef __input__ input #endif int MACD_Period_Slow = 29; // Period Slow
#ifdef __input__ input #endif int MACD_Period_Signal = 12; // Period for signal
#ifdef __input__ input #endif double MACD_Period_Ratio = 1.0; // Period ratio between timeframes (0.5-1.5)
#ifdef __input__ input #endif ENUM_APPLIED_PRICE MACD_Applied_Price = 1; // Applied Price
#ifdef __input__ input #endif int MACD_Shift = 6; // Shift
#ifdef __input__ input #endif int MACD_Shift_Far = -1; // Shift Far

/**
 * Indicator class.
 */
class I_MACD : public Indicator {

protected:
  // Enums.
  enum ENUM_MACD { MACD_FAST, MACD_SLOW, MACD_SIGNAL };

  public:

    /**
     * Class constructor.
     */
    void I_MACD(IndicatorParams &_params) : Indicator(_params) {
    }

    /**
     * Returns the indicator value.
     *
     * @docs
     * - https://docs.mql4.com/indicators/imacd
     * - https://www.mql5.com/en/docs/indicators/imacd
     */
    static double iMACD(
        string _symbol,
        ENUM_TIMEFRAMES _tf,
        uint _fast_ema_period,
        uint _slow_ema_period,
        uint _signal_period,
        ENUM_APPLIED_PRICE _applied_price,  // (MT4/MT5): PRICE_CLOSE, PRICE_OPEN, PRICE_HIGH, PRICE_LOW, PRICE_MEDIAN, PRICE_TYPICAL, PRICE_WEIGHTED
        int _mode,                          // (MT4 _mode): 0 - MODE_MAIN, 1 - MODE_SIGNAL
        int _shift = 0                      // (MT5 _mode); 0 - MAIN_LINE, 1 - SIGNAL_LINE
        ) {
      #ifdef __MQL4__
      return ::iMACD(_symbol, _tf, _fast_ema_period, _slow_ema_period, _signal_period, _applied_price, _mode, _shift);
      #else // __MQL5__
      double _res[];
      int _handle = ::iMACD(_symbol, _tf, _fast_ema_period, _slow_ema_period, _signal_period, _applied_price);
      return CopyBuffer(_handle, _mode, _shift, 1, _res) > 0 ? _res[0] : EMPTY_VALUE;
      #endif
    }
    double iMACD(
        uint _fast_ema_period,
        uint _slow_ema_period,
        uint _signal_period,
        ENUM_APPLIED_PRICE _applied_price,
        int _mode,
        int _shift = 0) {
      double _value = iMACD(GetSymbol(), GetTf(), _fast_ema_period, _slow_ema_period, _signal_period, _applied_price, _mode, _shift);
      CheckLastError();
      return _value;
    }

    /**
     * Get period value from settings.
     */
    uint GetPeriod(ENUM_MACD _macd_type) {
      switch (_macd_type) {
        default:
        case MACD_FAST: return MACD_Period_Fast;
        case MACD_SLOW: return MACD_Period_Slow;
      }
    }

    /**
     * Get MACD period signal value.
     */
    uint GetPeriodSignal() {
      return MACD_Period_Signal;
    }

    /**
     * Get shift value.
     */
    uint GetShift() {
      return MACD_Shift;
    }

    /**
     * Get applied price value from settings.
     */
    ENUM_APPLIED_PRICE GetAppliedPrice() {
      return MACD_Applied_Price;
    }

    /**
     * Calculates the Moving Average indicator.
     */
    bool Update() {
      bool _res = true;
      double _macd_main = iMACD(GetSymbol(), GetTf(), GetPeriod(MACD_FAST), GetPeriod(MACD_SLOW), GetPeriodSignal(), GetAppliedPrice(), LINE_MAIN, GetShift());
      double _macd_signal = iMACD(GetSymbol(), GetTf(), GetPeriod(MACD_FAST), GetPeriod(MACD_SLOW), GetPeriodSignal(), GetAppliedPrice(), LINE_SIGNAL, GetShift());
      _res |= Add(_macd_main, LINE_MAIN);
      _res |= Add(_macd_signal, LINE_SIGNAL);
      return _res;
    }
};
