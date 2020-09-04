# source script path :Use $BASH_SOURCE for bash, $0 is OK for zsh

export KYOKKO=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
echo Kyokko root path = $KYOKKO
