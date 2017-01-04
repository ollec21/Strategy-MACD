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
#include <EA31337-classes\Strategy.mqh>
#include <EA31337-classes\Strategies.mqh>

// User inputs.
#ifdef __input__ input #endif string __MACD_Parameters__ = "-- Settings for the Moving Averages Convergence/Divergence indicator --"; // >>> MACD <<<
#ifdef __input__ input #endif int MACD_Period_Fast = 19; // Period Fast
#ifdef __input__ input #endif int MACD_Period_Slow = 29; // Period Slow
#ifdef __input__ input #endif int MACD_Period_Signal = 12; // Period for signal
#ifdef __input__ input #endif double MACD_Period_Ratio = 1.0; // Period ratio between timeframes (0.5-1.5)
#ifdef __input__ input #endif ENUM_APPLIED_PRICE MACD_Applied_Price = 1; // Applied Price
#ifdef __input__ input #endif int MACD_Shift = 6; // Shift
#ifdef __input__ input #endif int MACD_Shift_Far = -1; // Shift Far
#ifdef __input__ input #endif double MACD_SignalLevel = 0.1; // Signal level
#ifdef __input__ input #endif int MACD_SignalMethod = 13; // Signal method for M1 (-31-31)

class MACD: public Strategy {
protected:

  double macd[H1][FINAL_ENUM_INDICATOR_INDEX][FINAL_SLINE_ENTRY];
  int       open_method = EMPTY;    // Open method.
  double    open_level  = 0.0;     // Open level.

    public:

  /**
   * Update indicator values.
   */
  bool Update(int tf = EMPTY) {
    // Calculates the Moving Averages Convergence/Divergence indicator.
    ratio = tf == 30 ? 1.0 : fmax(MACD_Period_Ratio, NEAR_ZERO) / tf * 30;
    for (i = 0; i < FINAL_ENUM_INDICATOR_INDEX; i++) {
      shift = i + MACD_Shift + (i == FINAL_ENUM_INDICATOR_INDEX - 1 ? MACD_Shift_Far : 0);
      macd[index][i][MODE_MAIN]   = iMACD(symbol, tf, (int) (MACD_Period_Fast * ratio), (int) (MACD_Period_Slow * ratio), (int) (MACD_Period_Signal * ratio), MACD_Applied_Price, MODE_MAIN,   shift);
      macd[index][i][MODE_SIGNAL] = iMACD(symbol, tf, (int) (MACD_Period_Fast * ratio), (int) (MACD_Period_Slow * ratio), (int) (MACD_Period_Signal * ratio), MACD_Applied_Price, MODE_SIGNAL, shift);
    }
    if (VerboseDebug) PrintFormat("MACD M%d: %s", tf, Arrays::ArrToString3D(macd, ",", Digits));
    success = (bool)macd[index][CURR][MODE_MAIN];
  }

  /**
   * Check if MACD indicator is on buy.
   *
   * @param
   *   cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   signal_method (int) - signal method to use by using bitwise AND operation
   *   signal_level (double) - signal level to consider the signal
   */
  bool Signal(int cmd, ENUM_TIMEFRAMES tf = PERIOD_M1, int signal_method = EMPTY, double signal_level = EMPTY) {
    bool result = FALSE; int period = Timeframe::TfToIndex(tf);
    // MA::Update(tf);
    MA::Update(tf);
    if (signal_method == EMPTY) signal_method = GetStrategySignalMethod(S_MACD, tf, 0);
    if (signal_level  == EMPTY) signal_level  = GetStrategySignalLevel(S_MACD, tf, 0);
    double gap = signal_level * pip_size;
    switch (cmd) {
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
        result = macd[period][CURR][MODE_MAIN] > macd[period][CURR][MODE_SIGNAL] + gap; // MACD rises above the signal line.
        if ((signal_method &   1) != 0) result &= macd[period][FAR][MODE_MAIN] < macd[period][FAR][MODE_SIGNAL];
        if ((signal_method &   2) != 0) result &= macd[period][CURR][MODE_MAIN] >= 0;
        if ((signal_method &   4) != 0) result &= macd[period][PREV][MODE_MAIN] < 0;
        if ((signal_method &   8) != 0) result &= ma_fast[period][CURR] > ma_fast[period][PREV];
        if ((signal_method &  16) != 0) result &= ma_fast[period][CURR] > ma_medium[period][CURR];
        break;
      case OP_SELL:
        result = macd[period][CURR][MODE_MAIN] < macd[period][CURR][MODE_SIGNAL] - gap; // MACD falls below the signal line.
        if ((signal_method &   1) != 0) result &= macd[period][FAR][MODE_MAIN] > macd[period][FAR][MODE_SIGNAL];
        if ((signal_method &   2) != 0) result &= macd[period][CURR][MODE_MAIN] <= 0;
        if ((signal_method &   4) != 0) result &= macd[period][PREV][MODE_MAIN] > 0;
        if ((signal_method &   8) != 0) result &= ma_fast[period][CURR] < ma_fast[period][PREV];
        if ((signal_method &  16) != 0) result &= ma_fast[period][CURR] < ma_medium[period][CURR];
        break;
    }
    result &= signal_method <= 0 || Convert::ValueToOp(curr_trend) == cmd;
    if (VerboseTrace && result) {
      PrintFormat("%s:%d: Signal: %d/%d/%d/%g", __FUNCTION__, __LINE__, cmd, tf, signal_method, signal_level);
    }
    return result;
  }

};
