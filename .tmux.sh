#!/bin/bash

[ $(tput cols) -lt 240 ] && narrowp=1 || narrowp=0
$(tmux list-session | grep -q attached) && attachedp=1 || attachedp=0
nsession=$(tmux list-session | wc -l)
echo $narrowp $attachedp $nsession
