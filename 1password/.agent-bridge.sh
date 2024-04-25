# Code extracted from https://stuartleeks.com/posts/wsl-ssh-key-forward-to-windows/ with minor modifications
# Code further extracted from https://dev.to/d4vsanchez/use-1password-ssh-agent-in-wsl-2j6m with modifications to behavior.

# Configure ssh forwarding
export SSH_AUTH_SOCK=$HOME/.1password/agent.sock
# need `ps -ww` to get non-truncated command for matching
# use square brackets to generate a regex match for the process we want but that doesn't match the grep command running it!
# we use tr and cut to get the process id for each. If they are running then we restart them by killing them

AGENT_RUNNING=$(ssh-add -l >/dev/null 2>&1; echo $?)

if [[ $AGENT_RUNNING != "0" ]]; then
    PIPE_PID=$(ps -axww | grep -q "[n]piperelay.exe -ei -s //./pipe/openssh-ssh-agent" | tr -s " " | cut -d " " -f 2)

    # We need to recreate the pipe. So lets get rid of the process and the file if they exist.
    if [[ ! -z $PIPE_PID ]]; then
        echo "Killing pipe process..."
        kill -9 $PIPE_PID
    fi

    if [[ -S $SSH_AUTH_SOCK ]]; then
        echo "Removing previous socket..."
        rm $SSH_AUTH_SOCK
    fi

    echo "Starting SSH-Agent relay..."
    # setsid to force new session to keep running
    # set socat to listen on $SSH_AUTH_SOCK and forward to npiperelay which then forwards to openssh-ssh-agent on windows
    (setsid socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &)
fi
