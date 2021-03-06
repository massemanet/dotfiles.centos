#!/bin/bash
# set up three panes; emacs, erl, bash.
# change layout depending on how wide the terminal is.

# make sure we have exactly one session
# if there is no session, start it, and start emacs in pane 0, erl in pane 1
nsession=$(2>/dev/null tmux list-session | wc -l)
if [ $nsession -gt 1 ]; then
    echo "many sessions"
    exit 0
elif [ $nsession -eq 0 ]; then
    tmux new-session -d
    tmux send-keys -t 0 "emacs -nw" C-m
    tmux split-window
    tmux send-keys -t 1 "erl -sname erl@localhost -pa ~/git/eper/ebin" C-m
    tmux split-window
    sleep 1
fi

# check if the term is narrow/wide, set layout accordingly
W=$(tmux list-sessions | grep -Eo "\[[0-9]*x" | cut -f1 -d"x" | cut -f2 -d"[")
[ $W -lt 240 ] && narrowp="t" || narrowp=""
if [ -n "$narrowp" ]; then
    tmux -q set-window-option main-pane-width 81
    tmux -q select-layout main-vertical
else
    tmux -q select-layout even-horizontal
    tmux -q resize-pane -t 1 -x 81
fi

# panes alist
panes=$(tmux list-panes -F "#P:#{pane_current_command}\n")  # introduced in 1.7

# move emacs, if it exists, to pane 0 (narrrow) or pane 1 (wide)
emacspane=$(echo $panes | grep -Eo "[0-9]*:emacs" | cut -f1 -d":" | head -1)
if [ -n "$emacspane" ]; then
    if [ -n "$narrowp" ]; then
        tmux swap-pane -s $emacspane -t 0
    else
        tmux swap-pane -s $emacspane -t 1
    fi
fi

# select a bash window, if there is one
bashpane=$(echo $panes | grep -Eo "[0-9]*:bash" | cut -f1 -d":" | head -1)
[ -n "$bashpane" ] && tmux select-pane -t $bashpane

# attach if needed
$(tmux list-session | grep -q attached) && attachedp="t" || attachedp=""
[ -n "$attachedp" ] || tmux attach
