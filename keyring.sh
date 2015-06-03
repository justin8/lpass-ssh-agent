#!/bin/bash

set -e

readonly LPASS_USER_FILE=~/.lpass_user

install() {
    pushd /tmp
    sudo apt-get update
    sudo apt-get -y install openssl libcurl3 libxml2 libssl-dev libxml2-dev libcurl4-openssl-dev pinentry-curses xclip asciidoc || { echo "Installation failed. Please try again and if it continues to fail open a github issue."; exit 1; }
    git clone https://github.com/lastpass/lastpass-cli.git
    cd lastpass-cli/
    make
    sudo make install
    sudo make install-doc
    popd
    rm -rf /tmp/lastpass-cli
    
    install-bashrc
    add-key ~/.ssh/id_rsa
    PS1='$ ' source ~/.bashrc
}

install-bashrc() {
    echo
    echo -n "Please enter lastpass email: "
    local EMAIL
    local ANSWER
    local CODE_EXISTS
    
    read EMAIL
    if [ -z "$EMAIL" ]; then 
        echo "No email provided, aborting."
        exit 1
    fi
    
    CODE="if [ -e $SCRIPT ]; then
    eval \$($SCRIPT start $EMAIL) &> /dev/null
    $SCRIPT ssh-add ~/.ssh/id_rsa || echo '$SCRIPT failed to unlock key ~/.ssh/id_rsa (perhaps your passphrase has changed?)'
    alias ssh-add=\"$SCRIPT ssh-add\"
fi"

    CODE_EXISTS=$(grep "$SCRIPT ssh-add" ~/.bashrc || echo)
    if [ ! -z "$CODE_EXISTS" ]; then
        echo "It looks like the ssh-agent code is already in your ~/.bashrc file. Skipping."
    else
        echo
        echo "This code will be added to your ~/.bashrc:"
        echo
        echo "$CODE"
        echo
        echo -n "Do you want to proceed [y/N]? "
        read ANSWER
        if [ "$ANSWER" == "y" ]; then
            echo "$CODE" >> ~/.bashrc
        fi
    fi
    
    echo "$EMAIL" > $LPASS_USER_FILE
    echo "Saved $EMAIL to $LPASS_USER_FILE"
}

login() {
    if lpass show i_should_not_exitst_dfvdfv 2>&1 | grep -q 'lpass login'; then
        lpass login --trust $(cat $LPASS_USER_FILE)
    fi
}

start() {
    local LPASS_USER=$1
    echo "$LPASS_USER" > $LPASS_USER_FILE
    
    login &> /dev/null
    
    if [ "$SSH_AUTH_SOCK" == "" ] ; then
        ssh-agent -s
    fi
}

ssh-add() {
    login
    
    local KEY=${1:-~/.ssh/id_rsa}
    local NAME
    
    NAME="ssh/$(hostname)/$(basename $KEY)"
    
    SSH_ASKPASS_PASSWORD="$(lpass show --password $NAME)"
    
    if [ -z $SSH_ASKPASS_PASSWORD ]; then
        /usr/bin/ssh-add $KEY
        exit
    fi
    
    export SSH_ASKPASS=$SCRIPT
    export SSH_ASKPASS_PASSWORD
    export DISPLAY=dummydisplay:0
    
    timeout 1 setsid /usr/bin/ssh-add $KEY </dev/null &>/dev/null
}

add-key() {
    local KEY=$1
    local PASSWORD
    local NAME
    local ANSWER
    
    echo "We are going to add a random key phrase to the ssh key '$KEY'. This key phrase will be stored in your lastpass account. A backup will be made before changing the key."
    echo
    echo -n "Do you want to proceed [y/N]? "
    read ANSWER
    if [ "$ANSWER" != "y" ]; then
        exit 1
    fi
    
    if [ ! -e $KEY.bak ]; then
        cp $KEY $KEY.bak
    fi
    
    login
    
    NAME="ssh/$(hostname)/$(basename $KEY)"
    PASSWORD=$(lpass generate --no-symbols $NAME 16)
    ssh-keygen -p -N "$PASSWORD" -f $KEY
    cat $KEY | lpass edit --non-interactive --notes $NAME
}

usage() {
    echo "Usage: $(basename $SCRIPT) [global options ...] COMMAND [commands options...]"
    echo
    echo "Lastpass ssh-agent keyring"
    echo
    echo "Global options:"
    echo "    --help                      show this help message"
    echo "    --debug                     trace bash commands"
    echo
    echo "Commands:"
    echo "    install           install lastpass client and configure your machine"
    echo "    add-key KEY       add an SSH key to the keyring"
    echo "    ssh-add KEY       wrapper for the ssh-add unix tool that adds the key using the passphrase saved in your lastpass account"
    echo
    exit 1
}

if [ -n "$SSH_ASKPASS_PASSWORD" ]; then
    echo "$SSH_ASKPASS_PASSWORD"
    exit 0
fi

cd $(dirname $0)
SCRIPT=$(pwd)/$(basename $0)

for ARG in "$@"; do
    case $ARG in
        --help|-h)
            usage
            ;;
        --debug)
            set -x
            shift
            ;;
        *)
            break
            ;;
    esac
done

if [ ! "$1" ]; then usage; fi

CMD=$1
shift

$CMD "$@"