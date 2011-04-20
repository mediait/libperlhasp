#!/bin/bash
ERRORCODE=0
if uname -p | grep 'x86_64' >/dev/null; then
	LIBPATH="/usr/local/lib64"
	echo -n "checking for 'libhasp_linux_x86_64_108230.so' in '$LIBPATH' ... "
	TEST=testhasp
	cat >${TEST}.c <<__END__
#include <stdio.h>
#include "hasp/hasp_api.h"

int main() {
	return 0;
}
__END__
	if LD_RUN_PATH=${LIBPATH} gcc -lhasp_linux_x86_64_108230 ${TEST}.c -o $TEST >/dev/null 2>&1; then
		echo "ok"
	else
		echo "not found"
		echo "trying to install ... "
		INSTALL=`which install`
		if ${INSTALL} -m 755 hasp/libhasp_linux_x86_64* ${LIBPATH}; then
			echo "libs installed successfully"
		else
			ERRORCODE=1
			echo "ERROR: cannot install x86_64 shared objects to '${LIBPATH}'"
			if [ ${USER} != "root" ]; then
				#echo "Try running '$0' as root"
				echo "Trying to rerun '$0' as root ..."
				echo "  sudo $0"
				sudo $0
				ERRORCODE=$?
			fi
		fi
	fi

	# clean up
	rm $TEST{,.c,.o} 2>/dev/null
fi

exit $ERRORCODE
