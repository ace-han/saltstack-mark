#!/bin/sh


ps -ef | grep saltpad | awk '{print $2}'| xargs kill -9