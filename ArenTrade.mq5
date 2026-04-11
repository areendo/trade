#property strict

string url = "http://127.0.0.1/update";

// escape string biar JSON aman
string EscapeJSONString(string s)
{
   StringReplace(s, "\\", "\\\\");
   StringReplace(s, "\"", "\\\"");
   StringReplace(s, "\r", "");
   StringReplace(s, "\n", " ");
   return s;
}

// ================= POSITIONS =================
string GetPositionsJSON()
{
   string json = "[";
   int written = 0;

   int total = PositionsTotal();

   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      if(!PositionSelectByTicket(ticket)) continue;

      if(written > 0) json += ",";

      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      string typeStr = (type == POSITION_TYPE_BUY) ? "BUY" : "SELL";

      string symbol = EscapeJSONString(PositionGetString(POSITION_SYMBOL));
      double volume = PositionGetDouble(POSITION_VOLUME);
      double open   = PositionGetDouble(POSITION_PRICE_OPEN);
      double profit = PositionGetDouble(POSITION_PROFIT);

      json += "{";
      json += "\"ticket\":" + IntegerToString((int)ticket) + ",";
      json += "\"symbol\":\"" + symbol + "\",";
      json += "\"type\":\"" + typeStr + "\",";
      json += "\"volume\":" + DoubleToString(volume,2) + ",";
      json += "\"open_price\":" + DoubleToString(open,5) + ",";
      json += "\"profit\":" + DoubleToString(profit,2);
      json += "}";

      written++;
   }

   json += "]";
   return json;
}

// ================= DEPOSIT (DEAL_TYPE_BALANCE) =================
string GetDepositsJSON()
{
   string json = "[";
   int written = 0;

   datetime from = TimeCurrent() - 86400 * 30; // 30 hari
   datetime to   = TimeCurrent();

   if(!HistorySelect(from, to))
      return "[]";

   int deals = HistoryDealsTotal();

   for(int i = 0; i < deals; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;

      long type = HistoryDealGetInteger(ticket, DEAL_TYPE);

      if(type == DEAL_TYPE_BALANCE)
      {
         if(written > 0) json += ",";

         datetime t = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         double amount = HistoryDealGetDouble(ticket, DEAL_PROFIT);

         json += "{";
         json += "\"time\":" + IntegerToString((int)t) + ",";
         json += "\"amount\":" + DoubleToString(amount,2);
         json += "}";

         written++;
      }
   }

   json += "]";
   return json;
}

// ================= SEND DATA =================
void SendData()
{
   long login   = AccountInfoInteger(ACCOUNT_LOGIN);
   double bal   = AccountInfoDouble(ACCOUNT_BALANCE);
   double eq    = AccountInfoDouble(ACCOUNT_EQUITY);

   string json = "{";
   json += "\"login\":" + IntegerToString((int)login) + ",";
   json += "\"balance\":" + DoubleToString(bal,2) + ",";
   json += "\"equity\":" + DoubleToString(eq,2) + ",";
   json += "\"positions\":" + GetPositionsJSON() + ",";
   json += "\"deposits\":" + GetDepositsJSON();
   json += "}";

   char post[];
   char result[];
   string result_headers;

   StringToCharArray(json, post, 0, StringLen(json));

   string headers = "Content-Type: application/json\r\n";
   int timeout = 5000;

   ResetLastError();
   int res = WebRequest("POST", url, headers, timeout, post, result, result_headers);

   if(res == -1)
   {
      Print("ArenTrade ERROR: ", GetLastError());
   }
   else
   {
      Print("ArenTrade OK: ", res);
   }
}

// ================= TIMER =================
int OnInit()
{
   EventSetTimer(2); // kirim tiap 2 detik
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   EventKillTimer();
}

void OnTimer()
{
   SendData();
}