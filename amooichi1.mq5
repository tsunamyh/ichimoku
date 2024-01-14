#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"

input int Inp_tenkan_sen    = 9;    // Ichimoku: period of Tenkan-sen
input int Inp_kijun_sen     = 26;   // Ichimoku: period of Kijun-sen
input int Inp_senkou_span_b = 52;   // Ichimoku: period of Senkou Span B

int  handle_iIchimoku;
bool first_cond  = false;
int  expire_cond = 0;

int OnInit() {
    handle_iIchimoku = iIchimoku(Symbol(), Period(), Inp_tenkan_sen, Inp_kijun_sen, Inp_senkou_span_b);
    //--- if the handle is not created
    if(handle_iIchimoku == INVALID_HANDLE) {
        //--- tell about the failure and output the error code
        PrintFormat("Failed to create handle of the iIchimoku indicator for the symbol %s/%s, error code %d",
                    Symbol(),
                    EnumToString(Period()),
                    GetLastError());
        //--- the indicator is stopped early
        return (INIT_FAILED);
    }
    return (INIT_SUCCEEDED);
}

void OnTick() {
    static datetime dtBarCurrent  = WRONG_VALUE;
    datetime        dtBarPrevious = dtBarCurrent;
    dtBarCurrent                  = iTime(_Symbol, _Period, 0);
    bool bNewBarEvent             = (dtBarCurrent != dtBarPrevious);

    if(bNewBarEvent) {
        double Ten_1   = MathRound(iIchimokuGet(TENKANSEN_LINE, 1) * pow(10, Digits())) / pow(10, Digits());
        double Kij_1   = MathRound(iIchimokuGet(KIJUNSEN_LINE, 1) * pow(10, Digits())) / pow(10, Digits());
        double SpanA_1 = MathRound(iIchimokuGet(SENKOUSPANA_LINE, 1) * pow(10, Digits())) / pow(10, Digits());
        double SpanB_1 = MathRound(iIchimokuGet(SENKOUSPANB_LINE, 1) * pow(10, Digits())) / pow(10, Digits());
        Print("Ten_1:>", Ten_1);
        Print("Kij_1:>", Kij_1);
        Print("SpanA_1:>", SpanA_1);
        Print("SpanB_1:>", SpanB_1);
        Print("Digits():>", Digits());
        double Ten_2   = MathRound(iIchimokuGet(TENKANSEN_LINE, 2) * pow(10, Digits())) / pow(10, Digits());
        double Kij_2   = MathRound(iIchimokuGet(KIJUNSEN_LINE, 2) * pow(10, Digits())) / pow(10, Digits());
        double SpanA_2 = MathRound(iIchimokuGet(SENKOUSPANA_LINE, 2) * pow(10, Digits())) / pow(10, Digits());
        double SpanB_2 = MathRound(iIchimokuGet(SENKOUSPANB_LINE, 2) * pow(10, Digits())) / pow(10, Digits());
        Print("Ten_2:>", Ten_2);
        Print("Kij_2:>", Kij_2);
        Print("SpanA_2:>", SpanA_2);
        Print("SpanB_2:>", SpanB_2);

        double close_1 = MathRound(iClose(Symbol(), Period(), 1) * pow(10, Digits())) / pow(10, Digits());
        if(first_cond && expire_cond < 6 && PositionSelect(_Symbol)) {
            expire_cond++;
            if(
                Ten_1 == Ten_2 &&
                Kij_1 == Kij_2 &&
                SpanA_1 == SpanA_2 &&
                SpanB_1 == SpanB_2) {
                double sl;
                double tp;
                double price;
                if(close_1 > Kij_1) {
                    price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
                    sl = Kij_1 - Point() * 50;
                    tp = price + (3 * (price - sl));
                    if(trade("ORDER_TYPE_BUY", "0.1", sl, tp)) {
                        first_cond  = false;
                        expire_cond = 0;
                    }
                }

                if(close_1 < Kij_1) {
                    price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
                    sl = Kij_1 + Point() * 50;
                    tp = price - (3 * (sl - price));
                    if(trade("ORDER_TYPE_SELL", "0.1", sl, tp)) {
                        first_cond  = false;
                        expire_cond = 0;
                    }
                }
            }
        }

        if(SpanA_1 == SpanB_1) {
            first_cond  = true;
            expire_cond = 0;
        }
    }
}

double iIchimokuGet(const int buffer, const int index) {
    double Ichimoku[1];
    //--- reset error code
    ResetLastError();
    //--- fill a part of the iIchimoku array with values from the indicator buffer that has 0 index
    if(CopyBuffer(handle_iIchimoku, buffer, index, 1, Ichimoku) < 0) {
        //--- if the copying fails, tell the error code
        PrintFormat("Failed to copy data from the iIchimoku indicator, error code %d", GetLastError());
        //--- quit with zero result - it means that the indicator is considered as not calculated
        return (0.0);
    }
    return (Ichimoku[0]);
}

bool trade(string type, string vl, double sl, double tp) {

    MqlTradeRequest request = {};
    MqlTradeResult  result  = {};

    if(type == "ORDER_TYPE_BUY") {
        request.type  = ORDER_TYPE_BUY;
        request.price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    }
    if(type == "ORDER_TYPE_SELL") {
        request.type  = ORDER_TYPE_SELL;
        request.price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    }

    request.action = TRADE_ACTION_DEAL;
    request.symbol = Symbol();
    request.volume = StringToDouble(vl);
    request.sl     = (sl);
    request.tp     = (tp);
    // request.magic    =StringToInteger(magic);
    // request.price        = (price);
    request.type_filling = ORDER_FILLING_FOK;
    request.deviation    = 5;
    // request.expiration   = TimeCurrent() + 1200 * 3;
    // request.type_time    = ORDER_TIME_SPECIFIED;
    Print(__FUNCTION__, request.price);
    bool success = OrderSend(request, result);
    Print("success: ", success);
    if(!success) {
        uint answer = result.retcode;
        Print("TradeLog: Trade request failed. Error = ", GetLastError());
        switch(answer) {
            //--- requote
            case 10004: {
                Print("TRADE_RETCODE_REQUOTE");
                Print("request.price = ", request.price, "   result.ask = ",
                      result.ask, " result.bid = ", result.bid);
                break;
            }
            //--- order is not accepted by the server
            case 10006: {
                Print("TRADE_RETCODE_REJECT");
                Print("request.price = ", request.price, "   result.ask = ",
                      result.ask, " result.bid = ", result.bid);
                break;
            }
            //--- invalid price
            case 10015: {
                Print("TRADE_RETCODE_INVALID_PRICE");
                Print("request.price = ", request.price, "   result.ask = ",
                      result.ask, " result.bid = ", result.bid);
                break;
            }
            //--- invalid SL and/or TP
            case 10016: {
                Print("TRADE_RETCODE_INVALID_STOPS");
                Print("request.sl = ", request.sl, " request.tp = ", request.tp);
                Print("result.ask = ", result.ask, " result.bid = ", result.bid);
                break;
            }
            //--- invalid volume
            case 10014: {
                Print("TRADE_RETCODE_INVALID_VOLUME");
                Print("request.volume = ", request.volume, "   result.volume = ",
                      result.volume);
                break;
            }
            //--- not enough money for a trade operation
            case 10019: {
                Print("TRADE_RETCODE_NO_MONEY");
                Print("request.volume = ", request.volume, "   result.volume = ",
                      result.volume, "   result.comment = ", result.comment);
                break;
            }
            //--- some other reason, output the server response code
            default: {
                Print("Other answer = ", answer);
            }
        }
        return false;
        //--- notify about the unsuccessful result of the trade request by returning false
    } else {
        return true;
    }
}