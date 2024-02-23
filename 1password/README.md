# [1Password Agent Bridge](#./.agent-bridge.sh)
This agent bridges the connection between the WSL ssh-agent and a Windows 1Password installation. This should be ran on every startup and can be added to your ``.bashrc`` file or your shell's equivalent. This also requires the [npiperelay](https://github.com/jstarks/npiperelay) utility to be installed.

This file does three different things:
1. Checks if the bridge and ssh-agent processes are running.
2. If they are not then start both processes.
3. If the bridge was re-created then before starting the process delete the agent.sock file associated so a new one can be created.
