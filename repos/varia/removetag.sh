#!/bin/bash

DIR=$1
TAG=$2

cd $DIR

#git fetch --prune --prune-tags
git tag -d $TAG