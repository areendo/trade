#include <Trade\Trade.mqh>

string url = "http://43.133.148.183/update";

void SendData()
{
   string json = "{";

   // ACCOUNT
   json += "\"login\":" + IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN)) + ",";
   json += "\"balance\":" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2) + ",";
   json += "\"equity\":" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2) + ",";

   // POSITIONS
   json += "\"positions\":[";
   int totalPos = PositionsTotal();

   for(int i=0;i<totalPos;i++)
   {
      ulong ticket = PositionGetTicket(i);

      if(PositionSelectByTicket(ticket))
      {
         json += "{";
         json += "\"ticket\":" + IntegerToString(ticket) + ",";
         json += "\"symbol\":\"" + PositionGetString(POSITION_SYMBOL) + "\",";
         json += "\"type\":\"" + (PositionGetInteger(POSITION_TYPE)==0?"BUY":"SELL") + "\",";
         json += "\"volume\":" + DoubleToString(PositionGetDouble(POSITION_VOLUME),2) + ",";
         json += "\"open_price\":" + DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN),5) + ",";
         json += "\"profit\":" + DoubleToString(PositionGetDouble(POSITION_PROFIT),2);
         json += "}";

         if(i < totalPos-1) json += ",";
      }
   }
   json += "],";

   // ORDERS
   json += "\"orders\":[";
   int totalOrd = OrdersTotal();

   for(int i=0;i<totalOrd;i++)
   {
      if(OrderSelect(i, SELECT_BY_POS))
      {
         json += "{";
         json += "\"ticket\":" + IntegerToString(OrderGetInteger(ORDER_TICKET)) + ",";
         json += "\"symbol\":\"" + OrderGetString(ORDER_SYMBOL) + "\",";
         json += "\"type\":\"" + EnumToString((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)) + "\",";
         json += "\"volume\":" + DoubleToString(OrderGetDouble(ORDER_VOLUME_CURRENT),2) + ",";
         json += "\"price\":" + DoubleToString(OrderGetDouble(ORDER_PRICE_OPEN),5);
         json += "}";

         if(i < totalOrd-1) json += ",";
      }
   }
   json += "]";

   json += "}";

   char result[];
   char post[];
   StringToCharArray(json, post);

   string headers = "Content-Type: application/json\r\n";

   int res = WebRequest("POST", url, headers, 5000, post, result, headers);

   if(res == -1)
   {
      Print("WebRequest Error: ", GetLastError());
   }
}

void OnTick()
{
   static datetime last = 0;

   if(TimeCurrent() - last < 2)
      return;

   last = TimeCurrent();

   SendData();
}