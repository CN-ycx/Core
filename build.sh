#!/bin/bash

FTP_HOST=$2
FTP_USER=$3
FTP_PSWD=$4

git fetch --unshallow
COUNT=$(git rev-list --count HEAD)
DATE=date --utc +"%Y/%m/%d %H:%M:%S"
FILE=$COUNT-$5-$6.zip

wget "http://www.sourcemod.net/latest.php?version=$1&os=linux" -q -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz

chmod +x addons/sourcemod/scripting/spcomp

for file in core.sp
do
  sed -i "s/<commit_num>/$COUNT/g" $file > output.txt
  sed -i "s/<commit_date>/$DATE/g" $file > output.txt
  rm output.txt
done

if [ ! -d "addons/sourcemod/scripting/core" ]; then
  mkdir addons/sourcemod/scripting/core
fi

cp include/* addons/sourcemod/scripting/include
cp core/* addons/sourcemod/scripting/core
cp core.sp addons/sourcemod/scripting

addons/sourcemod/scripting/spcomp -E -v0 $file

if [ ! -f "core.smx" ]; then
    echo "Compile core failed!"
    exit 1;
fi

zip -9rq $FILE core.smx core.sp core include LICENSE

lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O Core/$1/ $FILE"