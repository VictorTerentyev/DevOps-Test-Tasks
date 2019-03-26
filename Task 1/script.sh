#!/bin/bash

FILE_PATH=$1
IP=$(hostname -I)
CURRENT_DATE=$(date +'%d/%m/%Y %l:%M:%S')
HOME_FOLDER=$(eval echo ~$USER)
FIRST_NAME="John"
LAST_NAME="Doe"

i=2

while [ ${!i} != "-F" -a ${!i} != "-L" -a $i -le "$#" ] 2>/dev/null
do
  FILE_PATH="$FILE_PATH ${!i}"
  i=`expr $i + 1`
done

if [ "$1" = "" -o "$1" = "-F" -o "$1" = "-L" ] 2>/dev/null
  then
    echo "Please, set the path to input.yml"
    exit
fi

shift `expr $i - 1`

while getopts "F:L:" OPTIONS
do
  case "$OPTIONS" in
    F)
      FIRST_NAME=$OPTARG
      ;;
    L)
      LAST_NAME=$OPTARG
      ;;
  esac
done

sed -e "s/{{hostname}}/$HOSTNAME/g" -e "s/{{ip}}/$IP/g" -e "s@{{current_date}}@$CURRENT_DATE@g" -e "s@{{home_folder}}@$HOME_FOLDER@g" -e "s/{{username}}/$USER/g" -e "s/{{first_name}}/$FIRST_NAME/g" -e "s/{{last_name}}/$LAST_NAME/g" "$FILE_PATH" > output.yml 2>/dev/null