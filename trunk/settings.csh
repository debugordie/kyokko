# $_ isn't good when source command is called by history, like "!source"

setenv KYOKKO `dirname !$`
setenv KYOKKO `cd $KYOKKO && pwd`

echo Kyokko root path = $KYOKKO
