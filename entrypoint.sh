#!/bin/bash
set -e

nohup Xvfb :1 -screen 0 1024x768x16 &> xvfb.log &
DISPLAY=:1.0
export DISPLAY

source "/workspace/devel/setup.bash"
source "/usr/share/gazebo/setup.sh"

gripper="robotiq_2f_85"

roslaunch spawn_kortex_robot.launch gazebo_gui:=false gzweb:=true verbose:=true gripper:=$gripper  &

sleep 50

roslaunch controllers.launch gazebo_gui:=false gzweb:=true verbose:=true gripper:=$gripper  &

sleep 30

roslaunch move_it.launch gazebo_gui:=false gzweb:=true verbose:=true gripper:=$gripper  &

sleep 10

cd ~/gzweb
npm start &


sleep 30

python /home_robot.py


cd /workspace/src
jupyter notebook --ip=0.0.0.0 --allow-root

