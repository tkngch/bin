# Change directory with fzf.
#
# This script is intended to be sourced, not directory executed.

fcd() {
    local dir
    dir=$(find ./* -maxdepth 3 -type d -print 2> /dev/null | fzf +m)  &&
        cd "$dir" || return
}
