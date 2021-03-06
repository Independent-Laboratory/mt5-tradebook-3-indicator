//+------------------------------------------------------------------+
//|                           Copyright 2021, Independent Laboratory |
//|                                   https://www.independentlab.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Independent Laboratory"
#property link      "https://www.independentlab.net"
#property version   "1.00"

#property indicator_chart_window         // チャートウィンドウにグラフを表示
//--- indicator settings
#property indicator_buffers 1            // グラフの値を保存するバッファの個数
#property indicator_plots   1            // グラフの数
#property indicator_type1   DRAW_LINE    // グラフの種類 (線を描く)
#property indicator_color1  clrRed       // グラフの線の色 (赤)
#property indicator_width1  2            // グラフの線の太さ
#property indicator_style1  STYLE_SOLID  // グラフの線の種類 (実線)
#property indicator_label1  "SMA"        // グラフの名前

//--- input parameters
input int SMA_period = 14;                            // SMAの期間
input ENUM_APPLIED_PRICE applied_price = PRICE_CLOSE; // 適用価格

//--- indicator buffers
double SMABuffer[]; // グラフの値を保存するための配列 (=バッファ)
int SMA_Handle;     // SMAを操作するためのハンドラ


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   // SMABufferの中身がグラフ表示されるように関連付けを行う
   SetIndexBuffer(0, SMABuffer, INDICATOR_DATA);

   // SMAを操作するためのハンドラを用意する
   // 引数1: 銘柄名=現在のもの (NULLを指定)
   // 引数2: 時間足=現在のもの (0を指定)
   // 引数3: 平均期間=SMA_periodで指定された期間
   // 引数4: グラフをいくつ右にずらして表示するか (0を指定)
   // 引数5: 平均モード=SMAモード (他にEMAモードなどがある)
   // 引数6: 適用価格=applied_priceで指定されたもの
   SMA_Handle = iMA(NULL, 0, SMA_period, 0, MODE_SMA, applied_price);
   if (SMA_Handle == INVALID_HANDLE) {
      Print("SMAハンドラーの作成に失敗しました。エラーコード: ", GetLastError());
      return(INIT_FAILED);
   }

   // グラフの名前 (今回は特に効果はない)
   string short_name = StringFormat("%d SMAのサンプル", SMA_period);
   IndicatorSetString(INDICATOR_SHORTNAME, short_name);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   // レートの個数がSMAの期間分に達していない時間帯は
   // グラフの表示処理を行わない
   if (rates_total < SMA_period) {
      return(prev_calculated);
   }
   
   // 計算済みのSMAが準備できていることを確認する
   // 準備できていない場合はエラーメッセージと
   // エラーコード (GetLastError()) を表示して、
   // この回の計算は終了する
   int calculated = BarsCalculated(SMA_Handle);
   if(calculated <= 0) {
      Print("SMA_Handleのデータに不足があります。 エラーコード: ", GetLastError());
      return(prev_calculated);
   }
   
   // SMAの値のうち、グラフ表示用にコピーする個数を算出する
   int to_copy = 0;
   if (rates_total > prev_calculated) {
      to_copy = rates_total - prev_calculated;
   }
      
   // SMAの値を、グラフの値を保持するバッファーにコピーする
   // 引数1: ハンドラ
   // 引数2: ハンドラが持つバッファーのID (通常は0)
   // 引数3: コピー開始位置(時刻の新しい順に0, 1, 2, ...となる)
   // 引数4: コピーする値の数
   // 戻り値 = コピーされたデータ数
   if (CopyBuffer(SMA_Handle, 0, 0, to_copy, SMABuffer) <= 0) {
      Print("SMAの値が1個もとれませんでした。 エラーコード: ",GetLastError());
      return(prev_calculated);
   }
      
//--- return value of prev_calculated for next call
   // -1することで最新のレートのSMAは未表示扱いにする。
   // こうすることで、テクニカル指標が刻一刻と変化する。
   return(rates_total - 1); 
  }
//+------------------------------------------------------------------+
