#!/bin/bash
nohup Xvfb :1 -screen 0 1024x768x16 &> xvfb.log &
DISPLAY=:1.0
export DISPLAY

cd /root
git clone -b gzweb_1.4.0 https://github.com/osrf/gzweb.git
source "/workspace/devel/setup.bash"
source "/usr/share/gazebo/setup.sh"
cd /root/gzweb
./deploy.sh -m 
ls http/client/assets


