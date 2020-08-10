FROM osrf/ros:melodic-desktop-full

# using bash instead of sh to be able to source
ENV TERM xterm
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN apt-get update && \
    apt-get install -y wget cmake python-setuptools build-essential && \
    apt-get remove -y python-pip && \
    wget https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    pip2 install --upgrade packaging jupyter && \
    pip2 install --upgrade jupyter_contrib_nbextensions && \
    jupyter contrib nbextension install --system --symlink && \
    mkdir -p /root/.jupyter && \
    jupyter nbextension enable toc2/main

COPY jupyter_notebook_config.py /root/.jupyter/

RUN apt-get remove -y python-pip && \
    wget https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    pip2 install --upgrade packaging jupyter

RUN pip2 install --upgrade tensorflow keras h5py sklearn bokeh bayesian-optimization pandas

RUN apt-get update && \
apt install -y curl wget && \
curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
apt-get install -y nodejs && \
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
apt-get update && apt-get -y install yarn 

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y python-catkin-pkg python-catkin-tools python-empy python-nose  libgtest-dev ros-melodic-gazebo-* \
	    ros-melodic-control-toolbox \
            ros-melodic-moveit \
            ros-melodic-industrial-trajectory-filters \
            ros-melodic-gazebo-* \
            ros-melodic-gazebo-ros-pkgs \
            ros-melodic-gazebo-ros-control \
            ros-melodic-joint-state-controller \
            ros-melodic-effort-controllers \
            ros-melodic-position-controllers \
            ros-melodic-joint-trajectory-controller \
            ros-melodic-gripper-action-controller \
            gazebo9 libgazebo9-dev && \
    mkdir -p /workspace/src && \
    cd /workspace/ && \
    source /opt/ros/melodic/setup.bash 

RUN apt install -y python3 python3-pip  && \
    python3 -m pip install conan && \
    conan config set general.revisions_enabled=1 && \
    conan profile new default --detect > /dev/null && \
    conan profile update settings.compiler.libcxx=libstdc++11 default

COPY Glovebox-Simulator /workspace/src/

RUN source /opt/ros/melodic/setup.bash && \
    cd /workspace && \
    catkin_make  --cmake-args -DCMAKE_BUILD_TYPE=Release 

# installing gzweb
RUN apt-get update && \
DEBIAN_FRONTEND=noninteractive apt-get install -y  \
libjansson-dev \
libboost-dev imagemagick libtinyxml-dev mercurial cmake build-essential xvfb 

ENV GAZEBO_MODEL_PATH /workspace/src:/workspace/src/kortex_gazebo/models:~/.gazebo/models

COPY setup_gzweb.sh /workspace/src/
RUN /workspace/src/setup_gzweb.sh

RUN source /workspace/devel/setup.bash && \
rosrun xacro xacro.py -o /tmp/smart_grasping_sandbox.gazebo.urdf --inorder /workspace/src/kortex_description/robots/gen3.xacro dof:=7 vision:=true sim:=true &&\
 rosrun xacro xacro.py -o /tmp/smart_grasping_sandbox_gripper.gazebo.urdf --inorder /workspace/src/kortex_description/robots/gen3_robotiq_2f_85.xacro dof:=7 vision:=true sim:=true
#RUN sed -i s@package://@model://@g /tmp/smart_grasping_sandbox.gazebo.urdf && more /tmp/smart_grasping_sandbox.gazebo.urdf

# cleanup
RUN rm -rf /var/lib/apt/lists/*

# setup entrypoint
COPY ./entrypoint.sh /
COPY spawn_kortex_robot.launch /
COPY controllers.launch /
COPY move_it.launch /
COPY home_robot.py /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]

EXPOSE 8080 8888 7681
