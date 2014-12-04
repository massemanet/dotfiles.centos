#!/bin/bash

nsession=$(2>/dev/null tmux list-session | wc -l)
[ $nsession -gt 1 ] && echo "many sessions" && exit 0
if [ $nsession -eq 0 ]; then
    tmux new-session -d
    tmux send-keys -t 0 "emacs" C-m
    tmux split-window
    tmux send-keys -t 1 "erl" C-m
    tmux split-window
    [ $(tput cols) -lt 240 ] && narrowp="t" || narrowp=""
    if [ -z $narrowp ]; then
        tmux select-layout even-vertical
    else
        tmux select-layout main-vertical
    fi
fi

tmux swap-pane -s 0 -t 1
tmux list-panes -F "#P:#{pane_current_command}"

$(tmux list-session | grep -q attached) && attachedp="t" || attachedp=""
[ -z "$attachedp" ] && tmux attach && exit 0
