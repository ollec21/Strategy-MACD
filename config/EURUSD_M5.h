/*
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_MACD_Params_M5 : Indi_MACD_Params {
  Indi_MACD_Params_M5() : Indi_MACD_Params(indi_macd_defaults, PERIOD_M5) { shift = 0; }
} indi_macd_m5;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_MACD_Params_M5 : StgParams {
  // Struct constructor.
  Stg_MACD_Params_M5() : StgParams(stg_macd_defaults) {
    lot_size = 0;
    signal_open_method = 3;
    signal_open_filter = 1;
    signal_open_level = 0;
    signal_open_boost = 0;
    signal_close_method = 0;
    signal_close_level = 0;
    price_stop_method = 0;
    price_stop_level = 2;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_macd_m5;
