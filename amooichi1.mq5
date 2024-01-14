#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"

input int Inp_tenkan_sen    = 9;    // Ichimoku: period of Tenkan-sen
input int Inp_kijun_sen     = 26;   // Ichimoku: period of Kijun-sen
input int Inp_senkou_span_b = 52;   // Ichimoku: period of Senkou Span B

int handle_iIchimoku;

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
    //---
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
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
