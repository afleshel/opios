#!/bin/bash

: ${CURL_SCRIPT_PATH:=./libs/op/libs/ortc-lib/libs/curl-build-scripts}
: ${BOOST_SCRIPT_PATH:=./libs/op/libs/ortc-lib/libs/boost}
: ${SQLITE_SCRIPT_PATH:=./libs/op/libs/sqlite}
: ${TEMPLATES_PATH:=./templates}
: ${DESTINATION_PATH:=./Samples/OpenPeerSampleApp/OpenPeerSampleApp}

: ${CUSTOMER_SPECIFIC_TEMPLATE:=Template_CustomerSpecific.plist}
: ${CUSTOMER_SPECIFIC:=CustomerSpecific.plist}

: ${CUSTOMER_SPECIFIC_RELEASE_TEMPLATE:=Template_CustomerSpecific_Release.plist}
: ${CUSTOMER_SPECIFIC_RELEASE:=CustomerSpecific_Release.plist}

sdkpath() {
   echo Discovering SDK...

	platform=$1

	SDKCheck[0]="9.1"
	SDKCheck[1]="9.0.1"
	SDKCheck[2]="9.0"
	SDKCheck[3]="8.3.1"
	SDKCheck[4]="8.3"
	SDKCheck[5]="8.2.1"
	SDKCheck[6]="8.2"
	SDKCheck[7]="8.1.1"
	SDKCheck[8]="8.1"
    SDKCheck[9]="8.0"
    SDKCheck[10]="7.2"
    SDKCheck[11]="7.1"
    SDKCheck[12]="7.0"
    SDKCheck[13]="6.1"
    SDKCheck[14]="6.0"
    SDKCheck[15]="5.1"
    SDKCheck[16]="5.0.1"
    SDKCheck[17]="5.0"
    SDKCheck[18]="4.3"
    SDKCheck[19]="4.2"
    SDKCheck[20]="4.1"
    SDKCheck[21]="4.0"

    root="/Applications/Xcode.app/Contents/Developer/Platforms/${platform}.platform/Developer"
    oldRoot="/Developer/Platforms/${platform}.platform/Developer"

    if [ ! -d "${root}" ]
    then
        root="${oldRoot}"
    fi

    if [ ! -d "${root}" ]
    then
        echo " "
        echo "Oopsie.  You don't have an iOS SDK root in either of these locations: "
        echo "   ${root} "
        echo "   ${oldRoot}"
        echo " "
        echo "If you have 'locate' enabled, you might find where you have it installed with:"
        echo "   locate iPhoneOS.platform | grep -v 'iPhoneOS.platform/'"
        echo " "
        echo "and alter the 'root' variable in the script -- or install XCode if you can't find it... "
        echo " "
        exit 1
    fi

    SDK="unknown"

    for value in "${SDKCheck[@]}"
    do
       if [ -d "${root}/SDKs/${platform}${value}.sdk" ]
       then
           SDK="${value}"
           break
       fi
    done

    if [ "${SDK}" == "unknown" ]
    then
        echo " "
        echo "Unable to determine the SDK version to use."
        echo " "
        echo "If you have 'locate' enabled, you might find where you have it installed with:"
        echo "   locate iPhoneOS.platform | grep -v 'iPhoneOS.platform/'"
        echo " "
        echo "and alter the SDKCheck variables in the script -- or install XCode if you can't find it... "
        echo " "
        exit 1
    fi

    echo Found SDK in location "${root}/SDKs/${platform}${value}.sdk"
}

buildcurl() {

	#Runs curl build script
	if [ -f "$CURL_SCRIPT_PATH/build_curl" ]; then
		pushd $CURL_SCRIPT_PATH
			echo Building curl ...
			chmod a+x build_curl
			./build_curl --sdk-version ${SDK} --libcurl-version 7.38.0 --log info
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

}

buildboost() {
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
}

buildsqlite() {
	if [ -f "$SQLITE_SCRIPT_PATH/sqlite.sh" ]; then
		pushd $SQLITE_SCRIPT_PATH
			echo Building sqlite ...
			chmod a+x sqlite.sh
			sh sqlite.sh
			status=$?
			if [ $status != 0 ]; then
				echo $status
				echo "Sqlite build failed!"
				exit 1
			else
				echo "Sqlite build succeeded!"
			fi
		popd
	fi
}

customertemplates() {
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
}

sdkpath iPhoneOS
buildcurl
buildboost
buildsqlite
customertemplates
