# Code extracted from https://stuartleeks.com/posts/wsl-ssh-key-forward-to-windows/ with minor modifications

# Configure ssh forwarding
export SSH_AUTH_SOCK=$HOME/.1password/agent.sock

# need `ps -ww` to get non-truncated command for matching
# use square brackets to generate a regex match for the process we want but that doesn't match the grep command running it!
PIPE_ALREADY_RUNNING=$(ps -auxww | grep "[n]piperelay.exe -ei -s //./pipe/openssh-ssh-agent" | tr -s " " | cut -d " " -f 2)

AGENT_ALREADY_RUNNING=$(ps -auxww | grep " ssh-agent$" | tr -s " " | cut -d " " -f 2)

if [[ -z "$AGENT_ALREADY_RUNNING" ]]; then
    echo "Starting SSH Agent..."
    eval "$(ssh-agent)" >> /dev/null
fi

if [[ -z "$PIPE_ALREADY_RUNNING" ]]; then
    if [[ -S $SSH_AUTH_SOCK ]]; then
        # not expecting the socket to exist as the forwarding command isn't running (http://www.tldp.org/LDP/abs/html/fto.html)
        echo "Removing previous socket..."
        rm $SSH_AUTH_SOCK
    fi
    echo "Starting SSH-Agent relay..."
    # setsid to force new session to keep running
    # set socat to listen on $SSH_AUTH_SOCK and forward to npiperelay which then forwards to openssh-ssh-agent on windows
    (setsid socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &) >/dev/null 2>&1
fi
