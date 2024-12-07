#!/usr/bin/env bash

set -e

USER=${USER:-"lean"}
GROUP=${GROUP:-"lean"}
UID=${UID:-1000}
GID=${GID:-1000}

# if uid or gid equal to 0, we just run the command directly
if [ $UID -eq 0 ] || [ $GID -eq 0 ]; then
    exec "$@"
fi

# there are serval cases we need to couple with
(
    exec 2>/dev/null

    # 1. duplicate user name, not same uid
    if [ $(getent passwd $USER) ]; then
        userdel -r $USER
    fi

    # 2. duplicate uid, not same name
    if [ $(getent passwd $UID) ]; then
        userdel -r $(getent passwd $UID | cut -d: -f1)
    fi

    # 3. duplicate group name with different gid
    if [ $(getent group $GROUP) ]; then
        groupdel -f $GROUP
    fi

    # 4. duplicate gid with different group name
    if [ $(getent group $GID) ]; then
        groupdel -f $(getent group $GID | cut -d: -f1)
    fi
)

groupadd -g $GID $GROUP
useradd -m -u $UID -g $GID $USER

# check if XDG_CACHE_HOME is set
if [ "$XDG_CACHE_HOME" != "" ]; then
    if [ ! -d "$XDG_CACHE_HOME" ]; then
        mkdir -p "$XDG_CACHE_HOME"
    fi
    chown -R $USER:$GROUP "$XDG_CACHE_HOME"
fi

exec gosu $USER:$GROUP "$@"