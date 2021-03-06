//+------------------------------------------------------------------+
//|                           Copyright 2021, Independent Laboratory |
//|                                   https://www.independentlab.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Independent Laboratory"
#property link      "https://www.independentlab.net"
#property version   "1.00"
#include <MovingAverages.mqh>  // 提供された関数を取り込む

#property indicator_separate_window         // 別ウィンドウにグラフを表示

#property indicator_buffers 6               // グラフの値を保存するバッファの個数
                                            //   1: MACD表示用
                                            //   2: Singal表示用
                                            //   3: ヒストグラム(上昇)表示用
                                            //   4: ヒストグラム(下降)表示用
                                            //   5: 短期EMA計算用
                                            //   6: 長期EMA計算用
                                            
#property indicator_plots   4               // 表示するグラフの数


// グラフ1 (MACDライン)
#property indicator_type1   DRAW_LINE       // グラフの種類 (線を描く)
#property indicator_color1  clrGold         // グラフの線の色 (ゴールド)
#property indicator_width1  1               // グラフの線の太さ
#property indicator_style1  STYLE_SOLID     // グラフの線の種類 (実線)
#property indicator_label1  "MACD"          // グラフの線の名前

// グラフ2 (シグナルライン)
#property indicator_type2   DRAW_LINE       // グラフの種類 (線を描く)
#property indicator_color2  clrSilver       // グラフの色 (シルバー)
#property indicator_width2  1               // グラフの線の太さ
#property indicator_style2  STYLE_SOLID     // グラフの線の種類 (実線)
#property indicator_label2  "Signal"        // グラフの線の名前

// グラフ3 (ヒストグラム(上昇))
#property indicator_type3   DRAW_HISTOGRAM  // グラフの種類 (ヒストグラムを描く)
#property indicator_color3  clrGreen        // グラフの色 (緑)
#property indicator_width3  1               // グラフの線の太さ
#property indicator_style3  STYLE_SOLID     // グラフの線の種類 (実線)
#property indicator_label3  "Histogram_UP"  // グラフの線の名前

// グラフ4 (ヒストグラム(下降))
#property indicator_type4   DRAW_HISTOGRAM  // グラフの種類 (ヒストグラムを描く)
#property indicator_color4  clrRed          // グラフの色 (赤)
#property indicator_width4  1               // グラフの線の太さ
#property indicator_style4  STYLE_SOLID     // グラフの線の種類 (実線)
#property indicator_label4  "Histogram_DOWN"// グラフの線の名前 

//--- input parameters
input int fast_EMA_period = 12;             // 短期EMAの期間
input int slow_EMA_period = 26;             // 長期EMAの期間
input int signal_SMA_period = 9;            // シグナル線のSMAの期間
input ENUM_APPLIED_PRICE applied_price=PRICE_CLOSE; // 適用価格

//--- indicator buffers
double MACD_buffer[];       // MACDのグラフの値を保存するための配列
double signal_buffer[];     // シグナル線のグラフの値を保存するための配列
double hist_UP_buffer[];    // ヒストグラム(上昇)のグラフの値を保存するための配列
double hist_DOWN_buffer[];  // ヒストグラム(下降)のグラフの値を保存するための配列
double fast_EMA_buffer[];   // 短期EMAのグラフの値を一時的に保存するための配列
double slow_EMA_buffer[];   // 長期EMAのグラフの値を一時的に保存するための配列

int fast_EMA_handle; // 短期EMAを操作するためのハンドラの保存に使用
int slow_EMA_handle; // 長期EMAを操作するためのハンドラの保存に使用

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   // バッファとグラフの関連付け
   // MACD_bufferの中身がグラフ表示されるようにグラフ0番に関連付けを行う
   SetIndexBuffer(0, MACD_buffer, INDICATOR_DATA);
   
   // signal_bufferの中身がグラフ表示されるようにグラフ1番に関連付けを行う
   SetIndexBuffer(1, signal_buffer, INDICATOR_DATA); 
   
   // hist_UP_bufferの中身がグラフ表示されるようにグラフ2番に関連付けを行う
   SetIndexBuffer(2, hist_UP_buffer, INDICATOR_DATA);  
   
   // hist_DOWN_bufferの中身がグラフ表示されるようにグラフ3番に関連付けを行う
   SetIndexBuffer(3, hist_DOWN_buffer, INDICATOR_DATA);  
   
   // バッファと計算用の記憶領域の関連付け
   // fast_EMA_bufferの中身が記憶されるようにグラフ4番に関連付けを行う
   SetIndexBuffer(4, fast_EMA_buffer, INDICATOR_CALCULATIONS);
   
   // fast_EMA_bufferの中身が記憶されるようにグラフ5番に関連付けを行う
   SetIndexBuffer(5, slow_EMA_buffer, INDICATOR_CALCULATIONS);
   
   // テクニカル指標のハンドラの用意
   // --- 短期EMA ---
   // 引数1: 銘柄名=現在のもの (NULLを指定)
   // 引数2: 時間足=現在のもの (0を指定)
   // 引数3: 平均期間=fast_EMA_periodで指定された期間
   // 引数4: グラフをいくつ右にずらして表示するか (0を指定)
   // 引数5: 平均モード=EMAモード
   // 引数6: 適用価格=applied_priceで指定されたもの
   fast_EMA_handle = iMA(NULL, 0, fast_EMA_period, 0, MODE_EMA, applied_price);
   if (fast_EMA_handle == INVALID_HANDLE) {
       Print("短期EMAハンドラーの作成に失敗しました。エラーコード: ", GetLastError());
       return(INIT_FAILED);
   }
   // --- 長期EMA ---
   // 引数1: 銘柄名=現在のもの (NULLを指定)
   // 引数2: 時間足=現在のもの (0を指定)
   // 引数3: 平均期間=slow_EMA_periodで指定された期間
   // 引数4: グラフをいくつ右にずらして表示するか (0を指定)
   // 引数5: 平均モード=EMAモード
   // 引数6: 適用価格=applied_priceで指定されたもの  
   slow_EMA_handle = iMA(NULL, 0, slow_EMA_period, 0, MODE_EMA, applied_price);
   if (slow_EMA_handle == INVALID_HANDLE) {
       Print("長期EMAハンドラーの作成に失敗しました。エラーコード: ", GetLastError());
       return(INIT_FAILED);
   }
   
   // グラフの名前 (ウィンドウの左上に表示される)
   string short_name = StringFormat("MACD (%d,%d,%d) ", 
                                    fast_EMA_period, 
                                    slow_EMA_period, 
                                    signal_SMA_period);
   IndicatorSetString(INDICATOR_SHORTNAME, short_name);

   Print("init OK");
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
   // レートの個数がEMAの期間分に達していない時間帯は
   // グラフの表示処理を行わない
   int max_period = slow_EMA_period;
   if (rates_total < max_period) {
      return(prev_calculated);
   }
   
   int calculated = 0;
   // 計算済みの短期EMAが準備できていることを確認する
   // 準備できていない場合はエラーメッセージと
   // エラーコード (GetLastError()) を表示して、
   // この回の計算は終了する
   calculated = BarsCalculated(fast_EMA_handle);
   if(calculated <= 0) {
      Print("短期EMAのデータに不足があります。 エラーコード: ", GetLastError());
      return(prev_calculated);
   }
   
   // 計算済みの長期EMAが準備できていることを確認する
   // 準備できていない場合はエラーメッセージと
   // エラーコード (GetLastError()) を表示して、
   // この回の計算は終了する
   calculated = BarsCalculated(slow_EMA_handle);
   if(calculated <= 0) {
      Print("長期EMAのデータに不足があります。 エラーコード: ", GetLastError());
      return(prev_calculated);
   }   
   
   // 取得するべき値の個数を算出する
   int to_copy = 0;
   if (rates_total > prev_calculated) {
      to_copy = rates_total - prev_calculated;
   }

   // 短期EMAの値をハンドラから取得し、バッファにコピーする
   if (CopyBuffer(fast_EMA_handle, 0, 0, to_copy, fast_EMA_buffer) <= 0) {
      Print("短期EMAの値のコピーに失敗しました。エラーコード: ", GetLastError());
      return(0);
   }
   
    // 長期EMAの値をハンドラから取得し、バッファにコピーする
   if (CopyBuffer(slow_EMA_handle, 0, 0, to_copy, slow_EMA_buffer) <= 0) {
      Print("長期EMAの値のコピーに失敗しました。エラーコード: ", GetLastError());
      return(prev_calculated);
   }

   // MACDの値を計算する    
   for (int i = prev_calculated; i < rates_total; i++) {
       MACD_buffer[i] = fast_EMA_buffer[i] - slow_EMA_buffer[i];
   }
   
   // MACDの値のSMAを計算し、バッファに保存する
   // 引数1, 引数2: 決まり文句
   // 引数3: 計算開始位置
   // 引数4: SMAの期間
   // 引数5: SMAの適用値
   // 引数6: 計算結果の保存先バッファ
   SimpleMAOnBuffer(rates_total, prev_calculated, 0, 
                    signal_SMA_period, MACD_buffer, signal_buffer);
   
   // ヒストグラムを作成する
   for (int i = prev_calculated + 1; i < rates_total; i++) {
      // ヒストグラムに表示したいMACDとシグナルの差分
      // (現在注目している時刻のもの)
      double hist_value_current = MACD_buffer[i] - signal_buffer[i]; 
      // ヒストグラムに表示したいMACDとシグナルの差分
      // (現在注目している時刻よりも１つ前の時刻のもの)
      double hist_value_previous = MACD_buffer[i - 1] - signal_buffer[i - 1]; 
      
      // 上昇が検出できたとき
      if (hist_value_previous <= hist_value_current) {
         // 上昇用のヒストグラムに表示用の値を入れておく
         hist_UP_buffer[i] = hist_value_current;
         // 下降用のヒストグラムには0を入れておく
         hist_DOWN_buffer[i] = 0;
      }
      // 下降が検出できたとき
      else if (hist_value_previous > hist_value_current) {
         // 上昇用のヒストグラムには0を入れておく
         hist_UP_buffer[i] = 0;
         // 下降用のヒストグラムに表示用の値を入れておく   
         hist_DOWN_buffer[i] = hist_value_current; 
      }
   }
      
//--- return value of prev_calculated for next call
   // -1することで最新のレートのSMAは未表示扱いにする。
   // こうすることで、テクニカル指標が刻一刻と変化する。
   return(rates_total - 1);
  }
//+------------------------------------------------------------------+
