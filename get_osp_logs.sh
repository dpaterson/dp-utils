#!/bin/bash

declare -a servers=("cntl0" "cntl1" "nova0" "nova1" "nova2" "nova3" "stor0" "stor1" "stor2")
# declare -a servers=("cntl0")

echo make sure ssh config correct
~/pilot/update_ssh_config.py

echo Blow away and recreate log directory
sudo rm -rf ~/os-logs
mkdir ~/os-logs


for sname in "${servers[@]}"; do
  # copy remote logs to place where heat admin can get them
  echo "move logs around on $sname"
  ssh heat-admin@$sname "rm -rf ~/${sname}; mkdir ~/${sname}; sudo cp /var/log/messages ~/${sname}; sudo chmod 777 ~/${sname}/messages; sudo cp /var/log/os-apply-config.log ~/${sname}"
  echo scp logs back to director
  rm -rf ~/os-logs/$sname
  mkdir ~/os-logs/$sname
  scp -r heat-admin@$sname:~/$sname ~/os-logs/
done

echo get heat logs from director
rm -rf ~/os-logs/director-heat-logs
mkdir ~/os-logs/director-heat-logs
# sudo cp /var/log/heat/*.log ~/os-logs/director-heat-logs
sudo find /var/log/heat/ -name '*.log' -exec cp -vuni '{}' ~/os-logs/director-heat-logs/ ";"

echo run sosreport
sudo sosreport --batch --ticket-number=1455224 --tmp-dir=os-logs

echo chmod stuff
sudo chmod  777 ~/os-logs/sosreport*.*

echo copy rc files for undercloud and overcloud

sudo cp ~/stackrc ~/os-logs/
sudo cp ~/r8rc ~/os-logs/

echo tar it up!
sudo rm -f dell-os-logs.tar.*
sudo tar -zcvf ~/dell-os-logs.tar.gz ~/os-logs/*

echo split the tar
sudo split -b 10M -d ~/dell-os-logs.tar.gz dell-os-logs.tar.gz.

echo doneski!

