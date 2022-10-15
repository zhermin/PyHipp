#!/bin/bash

x=0
while [ $x -le 63 ]
  do echo $x
  conda create --name cenv$x --clone env1 --copy
  x++
done

aws sns publish --topic-arn arn:aws:sns:ap-southeast-1:298402190365:awsnotify --message "CondaCreateComplete"
