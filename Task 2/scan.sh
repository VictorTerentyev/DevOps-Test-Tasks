#!/bin/bash

DIR_PATH=$1

i=2

while [ ${!i} != "-H" -a ${!i} != "-P" -a ${!i} != "-D" -a ${!i} != "-U" -a ${!i} != "-p" -a $i -le "$#" ] 2>/dev/null
do
  DIR_PATH="$DIR_PATH ${!i}"
  i=`expr $i + 1`
done

if [ "$1" = "" -o "$1" = "-H" -o "$1" = "-P" -o "$1" = "-D" -o "$1" = "-U" -o "$1" = "-p" ] 2>/dev/null
  then
    echo "Please, set the path to directory"
    exit
fi

shift `expr $i - 1`

while getopts "H:P:D:U:p:" OPTIONS
do
  case "$OPTIONS" in
    H)
      DB_HOST=$OPTARG
      ;;
    P)
      DB_PORT=$OPTARG
      ;;
    D)
      DB_SCHEMA=$OPTARG
      ;;
    U)
      DB_USER=$OPTARG
      ;;
    p)
      DB_PASSWORD=$OPTARG
      ;;
  esac
done

DIR_PATH=$(readlink -f "$DIR_PATH")

scan () {
  names=$(find "$DIR_PATH" -type f | rev | sort -t/ -k1 | cut -d'/' -f-1 | rev | awk -v q="'" '{print q$0q}')
  paths=$(find "$DIR_PATH" -type f | rev | sort -t/ -k1 | rev | awk -F/ '{NF=NF-1;$NF=$NF"/"}1' OFS=/ | awk -v q="'" '{printf q$0q"\n"}')
  sizes=$(find "$DIR_PATH" -type f -exec du -ah {} +)
  sizes=$(echo "$sizes" | rev | sort -t/ -k1 | rev | awk -v q="'" '{print q$1q}')
  inodes=$(find "$DIR_PATH" -type f -exec ls -R -i {} +)
  inodes=$(echo "$inodes" | rev | sort -t/ -k1 | rev | awk '{print $1}')
  disk=$(find "$DIR_PATH" -type f -exec df -h {} +)
  disk=$(echo "$disk" | awk 'NR==2{print $1}')
  
  while read -r line
    do
      date=$(sudo debugfs -R 'stat <'"$line"'>' "$disk" 2>/dev/null | awk 'NR==10{for(i=4;i<=NF;++i) printf $i"\t"}' | awk -F" " '{NF=NF;$NF=$NF""}1' OFS=" ")
      if [ -z ${dates+x} ] 
        then
          dates=$(echo "'$date'")
        else
          dates=$(printf "$dates\n'$date'")
      fi
  done <<< "$inodes"
}

join () {
  info=$(paste <(echo "$names") <(echo "$paths") <(echo "$sizes") <(echo "$dates") | awk '$1=$1' FS=$'\t' OFS=", ")
}

query () {
  insert=$(echo "$info" | awk 'NR=NR{printf "INSERT INTO files (file_name, absolute_path, size, date)\nVALUES ("; for(i=1; i<=NF; i++) printf $i; printf ");\n"}')
  query="
    CREATE TABLE IF NOT EXISTS files (
      file_name varchar(100),
      absolute_path varchar(255),
      size varchar(10),
      date varchar(25)
    );

    $insert
  "
}

connect () {
  container=$(sudo docker ps | awk 'NR==2{print $NF}')
  sudo docker exec --tty "$container" mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_SCHEMA" -e "$query"
  echo $'\a'
}

scan
join
query
connect
