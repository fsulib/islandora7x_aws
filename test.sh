#!/bin/bash
export TESTVAR=helloworld
wget https://raw.githubusercontent.com/fsulib/islandora7x_aws/master/UserData/drupal.sh
sh drupal.sh > output.txt
