#!/usr/bin/env bash
set -xve

USER=${USER:-"lean"}
GROUP=${GROUP:-"lean"}
UID=${UID:-1000}
GID=${GID:-1000}

# there are serval cases we need to couple with
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

groupadd -g $GID $GROUP
useradd -m -u $UID -g $GID $USER

exec gosu $USER:$GROUP "$@"