eval $(ssh-agent) > /dev/null 2> /dev/null
ssh-add ~/.ssh/$HOST > /dev/null 2> /dev/null
export PATH="/home/aidanb/.emacs.d/bin:$PATH"
