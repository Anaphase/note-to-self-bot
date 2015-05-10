#/bin/bash

now=$(date +"%m-%d-%Y %H:%M:%S")

if [ -z $1 ] || ([ $1 != 'stop' ] && [ $1 != 'start' ] && [ $1 != 'restart' ])
then

  echo 'first parameter must be "stop", "start", or "restart"'
  exit 1

fi

if [ -z $2 ] || ([ $2 != 'api' ] && [ $2 != 'bot' ])
then

  echo 'second parameter must be "api" or "bot"'
  exit 1

fi

if [ $1 == 'stop' ] || [ $1 == 'restart' ]
then

  ./node_modules/forever/bin/forever stop "ntsb-$2.coffee"

fi

if [ $1 == 'start' ] || [ $1 == 'restart' ]
then

  rm -f ~/.forever/ntsb-$2.log

  mkdir "logs/$2/$now"
  touch "logs/$2/$now/out.log"
  touch "logs/$2/$now/error.log"

  cd "logs/$2"
  rm -f "current"
  ln -s "$now" "current"
  cd "../.."

  ./node_modules/forever/bin/forever start --minUptime 1000 --spinSleepTime 1000 -v -l "ntsb-$2.log" -o "logs/$2/$now/out.log" -e "logs/$2/$now/error.log" -c coffee "ntsb-$2.coffee"

fi
