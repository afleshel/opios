#!/bin/bash

: ${PATHTOCURLSCRIPT:=./libs/op/libs/ortc-lib/libs/curl}
: ${PATHTOBOOSTSCRIPT:=./libs/op/libs/ortc-lib/libs/boost}
: ${PATHTOCREDENTIALSTEMPLATE:=./templates}
: ${PATHTOCREDENTIALSDESTINATION:=./Samples/OpenPeerSampleApp/OpenPeerSampleApp}

#: ${CREDENTIALSTEMPLATEHEADER:=Template_CustomerSpecific.h}
: ${CREDENTIALSTEMPLATESOURCE:=Template_CustomerSpecific.m}
: ${CREDENTIALSHEADER:=CustomerSpecific.h}
: ${CREDENTIALSSOURCE:=CustomerSpecific.m}

: ${CREDENTIALSTEMPLATEJSON:=defaultLoginSettings.json}
: ${CREDENTIALJSON:=loginSettings.json}

#Runs curl build script
if [ -f "$PATHTOCURLSCRIPT/build_ios.sh" ]; then
	pushd $PATHTOCURLSCRIPT
		echo Building curl ...
		chmod a+x build_ios.sh
		sh build_ios.sh
		status=$?
		if [ $status != 0 ]; then
			echo $status
			echo "Curl build failed!"
			exit 1
		else
			echo "Curl build succeeded!"
		fi
	popd
else
	echo ERROR. Curl build failed. No such a file or directory.
fi

#Runs boost build script
if [ -f "$PATHTOBOOSTSCRIPT/boost.sh" ]; then
	pushd $PATHTOBOOSTSCRIPT
		echo Building boost ...
		chmod a+x boost.sh
		sh boost.sh
		status=$?
		if [ $status != 0 ]; then
			echo $status
			echo "Boost build failed!"
			exit 1
		else
			echo "Boost build succeeded!"
		fi
	popd
else
	echo ERROR. Boost build failed. No such a file or directory.
fi

#Checks if source file already exists in the destination folder. If doesn't exist, copies the template cource in the destiantion folder, renames it and update name of the imported header.
if [ ! -f "$PATHTOCREDENTIALSDESTINATION/$CREDENTIALSSOURCE" ]; then
	if [ -d $PATHTOCREDENTIALSTEMPLATE ]; then
		if [ -f "$PATHTOCREDENTIALSTEMPLATE/$CREDENTIALSTEMPLATESOURCE" ]; then
			cp -r "$PATHTOCREDENTIALSTEMPLATE/$CREDENTIALSTEMPLATESOURCE" "$PATHTOCREDENTIALSDESTINATION/$CREDENTIALSSOURCE"
			#sed -i.bak -e s/"$CREDENTIALSTEMPLATEHEADER"/"$CREDENTIALSHEADER"/g "$PATHTOCREDENTIALSDESTINATION/$CREDENTIALSSOURCE"
			echo Created $CREDENTIALSSOURCE
			#rm $PATHTOCREDENTIALSDESTINATION/$CREDENTIALSSOURCE.bak
		else
			echo "Error. Template $CREDENTIALSTEMPLATESOURCE doesnt exist!"
		fi
	else
		echo Error. Invalid template directory!
	fi
else
	echo Using existing $CREDENTIALSSOURCE...
fi

#Checks if login settings file already exists in the destination folder. If doesn't exist, copies the template cource in the destiantion folder, renames it and update name of the imported header.
if [ ! -f "$PATHTOCREDENTIALSDESTINATION/$CREDENTIALJSON" ]; then
	if [ -d $PATHTOCREDENTIALSTEMPLATE ]; then
		if [ -f "$PATHTOCREDENTIALSTEMPLATE/$CREDENTIALSTEMPLATEJSON" ]; then
			cp -r "$PATHTOCREDENTIALSTEMPLATE/$CREDENTIALSTEMPLATEJSON" "$PATHTOCREDENTIALSDESTINATION/$CREDENTIALJSON"
			echo Created $CREDENTIALJSON
		else
			echo "Error. Template $CREDENTIALSTEMPLATEJSON doesnt exist!"
		fi
	else
		echo Error. Invalid template directory!
	fi
else
	echo Using existing $CREDENTIALJSON...
fi
