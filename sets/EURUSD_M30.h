//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_MACD_EURUSD_M30_Params : Stg_MACD_Params {
  Stg_MACD_EURUSD_M30_Params() {
    symbol = "EURUSD";
    tf = PERIOD_M30;
    MACD_Period = 2;
    MACD_Applied_Price = 3;
    MACD_Shift = 0;
    MACD_TrailingStopMethod = 6;
    MACD_TrailingProfitMethod = 11;
    MACD_SignalOpenLevel = 36;
    MACD_SignalBaseMethod = 0;
    MACD_SignalOpenMethod1 = 195;
    MACD_SignalOpenMethod2 = 0;
    MACD_SignalCloseLevel = 36;
    MACD_SignalCloseMethod1 = 1;
    MACD_SignalCloseMethod2 = 0;
    MACD_MaxSpread = 5;
  }
};
