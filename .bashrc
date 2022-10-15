# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
export PATH=$PATH:/data/src/PyHipp

# CD Shortcuts
shopt -s cdable_vars
export day=/data/picasso/20181105
export pyh=/data/src/PyHipp

alias day='cd /data/picasso/20181105'
alias pyh='cd /data/src/PyHipp'
