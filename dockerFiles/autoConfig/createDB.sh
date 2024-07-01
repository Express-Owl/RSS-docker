#!/bin/sh
# Check the condition from .env file
if [ "$AUTO_EXECUTE_CONFIG" = "true" ]; then
  i=0
  while [ "$i" -lt "$RETRY_TIMEOUT_COUNT" ]; do
    sleep 2
    response=$(curl -s -X POST -d "install_changeLngLeed=fr&root=http%3A%2F%2Fweb_server%3A80&mysqlHost=sql_server%3A$MYSQL_PORT&mysqlLogin=$MYSQL_USER&mysqlMdp=$MYSQL_PASSWORD&mysqlBase=$MYSQL_DATABASE&mysqlPrefix=leed__&login=admin&password=admin&installButton=" "http://web_server:80/install.php")
    
    # Check if the response contains mysql error message
    if echo "$response" | grep -q "Connection refused"; then
      remaining_tries=$((RETRY_TIMEOUT_COUNT - i))
      echo "Connection refused. Config execution failed. $remaining_tries tries before timeout. Retrying in 500ms..."
    else
      echo "Config executed successfully. Exiting."
      exit 0
    fi

    i=$((i + 1))
  done
else
  echo "Skipping config execution."
fi
