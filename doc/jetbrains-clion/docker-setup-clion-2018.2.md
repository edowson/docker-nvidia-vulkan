# Docker Setup CLion-2018.2

CLion-2018.2 can be run from a docker container. These instructions have been
tested on the following operating systems and processor architectures:
- Ubuntu-16.04 amd64 architecture
- Ubuntu-16.04 arm64v8 architecture

## Install Required Packages

CLion requires a JDK to run. Ensure that you have a JDK installed
and that either one of the following environment variables
`CLION_JDK`, `JDK_HOME` or `JAVA_HOME` have been set.

For arm64v8 platforms, install the openjdk-8-jdk package:

```bash
sudo apt install openjdk-8-jdk
```

## Install CLion-2018.2

Download the CLion installer for linux and extract its contents to a docker
volume mount point:
```
~/mount/tool/jetbrains/clion-2018.2.4
```

## Configure CLion-2018.2

Update `IDE_HOME\bin\idea.properties` to change the default directories for storing
user preferences and plugins.

```bash
nano ~/mount/tool/jetbrains/clion-2018.2.4/bin/idea.properties

#---------------------------------------------------------------------
# Directories used for volume mounts.
#---------------------------------------------------------------------
dir.backup=/backup
dir.data=/data
dir.project=/project
dir.tool=/tool

#---------------------------------------------------------------------
# Customize path to IDE config folder.
#---------------------------------------------------------------------
idea.config.path=${dir.data}/.clion-2018.2/config

#---------------------------------------------------------------------
# Customize path to IDE system folder.
#---------------------------------------------------------------------
idea.system.path=${dir.data}/.clion-2018.2/system
```

Update `IDE_HOME\bin\clion64.vmoptions` to change the location of java user
preferences

```bash
nano ~/mount/tool/jetbrains/clion-2018.2.4/bin/clion64.vmoptions

-Djava.util.prefs.systemRoot=/data/.java
-Djava.util.prefs.userRoot=/data/.java/.userPrefs
```

Install required packages:
```
sudo apt update
sudo apt install -y \
libasound2 \
libcap2 \
libgconf-2-4 \
libgcrypt20 \
libgtk2.0-0 \
libgtk-3-0 \
libnotify4 \
libnss3 \
libx11-xcb1 \
libxkbfile1 \
libxss1 \
libxtst6 \
libgl1-mesa-glx \
libcanberra-gtk-module \
libcanberra-gtk3-module \
packagekit-gtk3-module
```

Source setup.bash
```bash
source $WORKSPACE/devel/setup.bash
export WORKSPACE_PRJ=/project/intensive-ros/catkin_ws
source $WORKSPACE_PRJ/devel/setup.bash
cd $WORKSPACE_PRJ
```

Launch clion
```bash
/tool/jetbrains/clion-2018.2.4/bin/clion.sh
```

### ARM64v8 Specific Configuration

When prompted to customize CLion and configure toolchains, manually specify
the CMake executable instead of using the bundled CMake:
```
CMake: /usr/local/bin/cmake
Debugger: /usr/bin/gdb
```

Add additional file types:
- `C/C++: *.cu`

### Install Plugins

Install the following plugins:
- .ignore
- Bash Support
- CLion CUDA Run Patcher
- MarkDown Support


## Technotes

- [Customizing PyCharm](https://www.jetbrains.com/help/pycharm/configuring-project-and-ide-settings.html)
- [Changing IDE default directories used for config, plugins, and caches storage](https://intellij-support.jetbrains.com/hc/en-us/articles/207240985-Changing-IDE-default-directories-used-for-config-plugins-and-caches-storage)
- [Changing default Java user preferences directory java.util.prefs.systemRoot and java.util.prefs.userRoot](https://intellij-support.jetbrains.com/hc/en-us/community/posts/360000029344-Changing-default-Java-user-preferences-directory-java-util-prefs-systemRoot-and-java-util-prefs-userRoot)
