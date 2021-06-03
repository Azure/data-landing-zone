#!/bin/bash

# Define Parameters
mysqlserverid=${mysqlserverid}

# Parse Parameters
while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare "$param"="$2"
        # echo $1 $2 // Optional to see the parameter:value result
   fi

  shift
done

# Restart MySql Server
echo "Restarting MySql Server"
az mysql server restart \
    --ids "$mysqlserverid"
