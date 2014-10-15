#!/bin/bash

: ${CURL_SCRIPT_PATH:=./libs/op/libs/ortc-lib/libs/curl-build-scripts}
: ${BOOST_SCRIPT_PATH:=./libs/op/libs/ortc-lib/libs/boost}
: ${TEMPLATES_PATH:=./templates}
: ${DESTINATION_PATH:=./Samples/OpenPeerSampleApp/OpenPeerSampleApp}

: ${CUSTOMER_SPECIFIC_TEMPLATE:=Template_CustomerSpecific.plist}
: ${CUSTOMER_SPECIFIC:=CustomerSpecific.plist}

: ${CUSTOMER_SPECIFIC_RELEASE_TEMPLATE:=Template_CustomerSpecific_Release.plist}
: ${CUSTOMER_SPECIFIC_RELEASE:=CustomerSpecific_Release.plist}

#Runs curl build script
if [ -f "$CURL_SCRIPT_PATH/build_curl" ]; then
	pushd $CURL_SCRIPT_PATH
		echo Building curl ...
		chmod a+x build_curl
		./build_curl --sdk-version 8.0 --libcurl-version 7.38.0
		status=$?
		if [ $status != 0 ]; then
			echo $status
			echo "Curl build failed!"
			exit 1
		else
			if [ ! -f "curl/curl" ]; then
				ln -s ios-appstore/include curl/curl
				ln -s ios-appstore/lib curl/lib
			fi
			echo "Curl build succeeded!"
		fi
	popd
else
	echo ERROR. Curl build failed. No such a file or directory.
fi

#Runs boost build script
if [ -f "$BOOST_SCRIPT_PATH/boost.sh" ]; then
	pushd $BOOST_SCRIPT_PATH
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

#Checks if common settings file already exists in the destination folder. If doesn't exist, copies the template cource in the destiantion folder, renames it and update name of the imported header.
if [ ! -f "$DESTINATION_PATH/$CUSTOMER_SPECIFIC" ]; then
	if [ -d $TEMPLATES_PATH ]; then
		if [ -f "$TEMPLATES_PATH/$CUSTOMER_SPECIFIC_TEMPLATE" ]; then
			cp -r "$TEMPLATES_PATH/$CUSTOMER_SPECIFIC_TEMPLATE" "$DESTINATION_PATH/$CUSTOMER_SPECIFIC"
			echo Created $CUSTOMER_SPECIFIC
		else
			echo "Error. Template $CUSTOMER_SPECIFIC_TEMPLATE doesnt exist!"
		fi
	else
		echo Error. Invalid template directory!
	fi
else
	echo Using existing $CUSTOMER_SPECIFIC...
fi

#Checks if releas settings file already exists in the destination folder. If doesn't exist, copies the template cource in the destiantion folder, renames it and update name of the imported header.
if [ ! -f "$DESTINATION_PATH/$CUSTOMER_SPECIFIC_RELEASE" ]; then
	if [ -d $TEMPLATES_PATH ]; then
		if [ -f "$TEMPLATES_PATH/$CUSTOMER_SPECIFIC_RELEASE_TEMPLATE" ]; then
			cp -r "$TEMPLATES_PATH/$CUSTOMER_SPECIFIC_RELEASE_TEMPLATE" "$DESTINATION_PATH/$CUSTOMER_SPECIFIC_RELEASE"
			echo Created $CUSTOMER_SPECIFIC_RELEASE
		else
			echo "Error. Template $CUSTOMER_SPECIFIC_RELEASE_TEMPLATE doesnt exist!"
		fi
	else
		echo Error. Invalid template directory!
	fi
else
	echo Using existing $CUSTOMER_SPECIFIC_RELEASE...
fi
