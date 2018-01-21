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
      double _macd_main = Indicators::iMACD(GetSymbol(), GetTf(), GetPeriod(MACD_FAST), GetPeriod(MACD_SLOW), GetPeriodSignal(), GetAppliedPrice(), LINE_MAIN, GetShift());
      double _macd_signal = Indicators::iMACD(GetSymbol(), GetTf(), GetPeriod(MACD_FAST), GetPeriod(MACD_SLOW), GetPeriodSignal(), GetAppliedPrice(), LINE_SIGNAL, GetShift());
      _res |= Add(_macd_main, LINE_MAIN);
      _res |= Add(_macd_signal, LINE_SIGNAL);
      return _res;
    }
};
