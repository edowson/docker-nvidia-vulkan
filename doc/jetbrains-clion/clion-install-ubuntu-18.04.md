# CLion - Install Ubuntu-18.04

## Install required packages

```bash
sudo apt install libcanberra-gtk-module
```

## Install CLion

Extract the installation package
```bash
tax -xf *.tar.xz
```

Run the program:
```bash
/tool/jetbrains/clion-2019.1.4/bin/clion.sh
```

## Update host system configutation

For an intelligent IDE, it is essential to be in the know about any external changes in files it is working with - e.g. changes made by VCS, or build tools, or code generators etc. For that reason, IntelliJ platform spins background process to monitor such changes. The method it uses is platform-specific, and on Linux, it is the Inotify facility.

Inotify requires a "watch handle" to be set for each directory in the project. Unfortunately, the default limit of watch handles may not be enough for reasonably sized projects, and reaching the limit will force IntelliJ platform to fall back to recursive scans of directory trees.

To prevent this situation it is recommended to increase the watches limit (to, say, 512K):

1. Add the following line to either /etc/sysctl.conf file or a new `*.conf` file (e.g. `idea.conf`) under `/etc/sysctl.d/` directory:

```bash
sudo nano  /etc/sysctl.d/idea.conf

fs.inotify.max_user_watches = 524288
```

Then run this command to apply the change:

```bash
sudo sysctl -p --system
```

And don't forget to restart your IDE.

Note: the watches limit is per-account setting. If there are other programs running under the same account which also uses Inotify the limit should be raised high enough to suit needs of all of them.

Ref:
- [Inotify Watches Limit](https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit)
