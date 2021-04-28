#!/bin/bash

# variables
LOGFILE=$1
RESPONSE_CODE="200"
PREFIX_LV="2" # Monitor the Lv of slash
KEY_SIZE="12" # Condition of key filtering
KEY_DISPLAY="5" # Control the key display length

# Functions
wordcount() { sort | uniq -c; }
sort_desc() { sort -rn; }
return_top_ten() { head -10; }
filters()
{
  grep $RESPONSE_CODE \
| grep -v "\/rss\/" \
| grep -v robots.txt \
| grep -v "\.css" \
| grep -v "\.jss*" \
| grep -v "\.png" \
| grep -v "\.ico"
}

request_URL()
{
  awk -v prefix="$PREFIX_LV"  -v keySize="$KEY_SIZE"  -v keyDisplay="$KEY_DISPLAY" '
  func Req_URL(req, code, url) {
    split(url, str, "?")
    link = Proc_Link(str[1], prefix)
    parm = Proc_Parm(str[2], keySize, keyDisplay)
    return req " " code " " link " [ " parm "]";
  }

  func Proc_Link(link, prefix) {
    numSlash = gsub(/\//, "/", link)
    if (numSlash > prefix) {
      keyStr = ""
      n = split(link, pre, /\//)
      num = (n > prefix + 2) ? prefix + 2 : n
      for (i=2; i<num; i++) {
        keyStr = keyStr "/" pre[i]
      }
      return keyStr "/..."
    } else {
      return link
    }
  }

  func Proc_Parm(parm, keySize, keyDisplay) {
    keyStr = ""
    gsub(/amp;/, "", parm)
    n = split(parm, var, /&/)
    for (i=1; i<=n; i++) {
      split(var[i], key, /=/)
      if (length(key[1]) > keySize) {
        keyStr = keyStr substr(key[1], 1, keyDisplay) "..." " "
      } else {
        keyStr = keyStr key[1] " "
      }
    }
    return keyStr
  }

  BEGIN {}
  {print Req_URL($6, $9, $7)} 
  END {}' \
  | cut -d'"' -f2
}


# Action
request_Report()
{
  echo ""
  echo "Start to filter the access log"
  echo "=============== Start ==============="
  cat $LOGFILE \
| filters \
| request_URL \
| wordcount \
| sort_desc
  echo "================ End ================"
  echo ""
}


# Execute
if [ -z "$1" ]; then
  echo "Please input: ./accReport.sh {{file path}}"
else
  request_Report
fi