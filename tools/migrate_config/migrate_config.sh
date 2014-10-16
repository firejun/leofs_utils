#!/usr/bin/env bash

# 1.Current LeoFS Directory
# 2.New LeoFS Directory

CUR_DIR=$1
NEW_DIR=$2

if [ `echo $CUR_DIR | grep leo_manager` ]; then
  TYPE="manager"
elif [ `echo $CUR_DIR | grep leo_storage` ]; then
  TYPE="storage"
elif [ `echo $CUR_DIR | grep leo_gateway` ]; then
  TYPE="gateway"
fi

if [ -e ${CUR_DIR}/bin/leo_${TYPE} ]; then
  $CUR_DIR/bin/leo_${TYPE} stop
else
  echo $CUR_DIR/bin/leo_$TYPE not found
  exit 1
fi

cp -r $CUR_DIR/work/* $NEW_DIR/work/*
cp $NEW_DIR/etc/leo_$TYPE.conf $NEW_DIR/etc/leo_$TYPE.conf.org

ruby conv_conf.rb -c $CUR_DIR/etc/leo_$TYPE.conf -t $NEW_DIR/etc/leo_$TYPE.conf.new -o $NEW_DIR/etc/leo_$TYPE.conf

if [ -e $NEW_DIR/bin/leo_$TYPE ]; then
  $NEW_DIR/bin/leo_$TYPE start
else
  echo $NEW_DIR/bin/leo_$TYPE not found.
  exit 1
fi




