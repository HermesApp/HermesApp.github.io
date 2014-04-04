#!/bin/sh

set -e

SESSION_NAME='hermesapp'

if tmux has-session -t "$SESSION_NAME" >/dev/null 2>&1; then
    printf 'tmux session "%s" is already in use.\n' "$SESSION_NAME"
    printf 'Please kill off that session before running this script.\n'
    exit 1
fi

tmux new-session -d -s "$SESSION_NAME" 'bundle exec jekyll server'
tmux split-window -t "$SESSION_NAME" -v 'compass watch . -c ./_config/compass.rb'
tmux attach-session -t "$SESSION_NAME"
