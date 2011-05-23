#/bin/bash

cmd=$1

if   [ "$cmd" = "setup" ]; then

elif [ "$cmd" = ""      ]; then
  echo "Please specify a command for this script to run!"
  echo "Example: "
  echo " $0 pull"
fi