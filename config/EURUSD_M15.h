/*
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_MACD_Params_M15 : MACDParams {
  Indi_MACD_Params_M15() : MACDParams(indi_macd_defaults, PERIOD_M15) {
    applied_price = (ENUM_APPLIED_PRICE)2;
    ema_fast_period = 24;
    ema_slow_period = 30;
    shift = 0;
    signal_period = 8;
  }
} indi_macd_m15;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_MACD_Params_M15 : StgParams {
  // Struct constructor.
  Stg_MACD_Params_M15() : StgParams(stg_macd_defaults) {
    lot_size = 0;
    signal_open_method = 0;
    signal_open_filter = 1;
    signal_open_level = (float)0;
    signal_open_boost = 0;
    signal_close_method = 0;
    signal_close_level = (float)0;
    price_stop_method = 0;
    price_stop_level = (float)2;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_macd_m15;
