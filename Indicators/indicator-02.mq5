//+------------------------------------------------------------------+
//|                           Copyright 2021, Independent Laboratory |
//|                                   https://www.independentlab.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Independent Laboratory"
#property link      "https://www.independentlab.net"
#property version   "1.00"

#property indicator_chart_window         // チャートウィンドウにグラフを表示
//--- indicator settings
#property indicator_buffers 1            // グラフの値を保存する配列の数
#property indicator_plots   1            // グラフの数
#property indicator_type1   DRAW_LINE    // グラフの種類 (線を描く)
#property indicator_color1  clrRed       // グラフの線の色 (赤)
#property indicator_width1  2            // グラフの線の太さ
#property indicator_style1  STYLE_SOLID  // グラフの線の種類 (実線)
#property indicator_label1  "TEST"       // グラフの名前

//--- indicator buffers
double MyBuffer[]; // グラフの値を保存するための配列 (=バッファ)

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   // SMABufferの中身がグラフ表示されるように関連付けを行う
   SetIndexBuffer(0, MyBuffer, INDICATOR_DATA);

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
   Print("最新の終値:", close[rates_total - 1]);
   for (int i = prev_calculated; i < rates_total; i++) {
      MyBuffer[i] = close[i];
   }
      
//--- return value of prev_calculated for next call
   // -1することで最新のレートのグラフは未表示扱いにする。
   // こうすることで、テクニカル指標が刻一刻と変化する。
   return(rates_total - 1); 
                            
  }
//+------------------------------------------------------------------+
