#!/bin/bash

: ${TEMPLATES_PATH:=./templates}
: ${DESTINATION_PATH:=./Samples/OpenPeerSampleApp/OpenPeerSampleApp}

: ${CUSTOMER_SPECIFIC_TEMPLATE:=Template_CustomerSpecific.plist}
: ${CUSTOMER_SPECIFIC:=CustomerSpecific.plist}

: ${CUSTOMER_SPECIFIC_RELEASE_TEMPLATE:=Template_CustomerSpecific_Release.plist}
: ${CUSTOMER_SPECIFIC_RELEASE:=CustomerSpecific_Release.plist}

sdkpath() {
  platform=$1
  echo Discovering ${platform} SDK...

  major_start=13
  major_stop=4

  minor_start=15
  minor_stop=0

  subminor_start=5
  subminor_stop=0

    root="/Applications/Xcode.app/Contents/Developer/Platforms/${platform}.platform/Developer"
    oldRoot="/Developer/Platforms/${platform}.platform/Developer"

    if [ ! -d "${root}" ]
    then
        root="${oldRoot}"
    fi

    if [ ! -d "${root}" ]
    then
        echo " "
        echo "Oopsie.  You don't have an SDK root in either of these locations: "
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

    for major in `seq ${major_start} ${major_stop}`
    do
      for minor in `seq ${minor_start} ${minor_stop}`
      do
        for subminor in `seq ${subminor_start} ${subminor_stop}`
        do
          #echo Checking "${root}/SDKs/${platform}${major}.${minor}.${subminor}.sdk"
          if [ -d "${root}/SDKs/${platform}${major}.${minor}.${subminor}.sdk" ]
          then
            SDK="${major}.${minor}.${subminor}"
          echo Found SDK in location "${root}/SDKs/${platform}${SDK}.sdk"
            return
          fi
        done
        #echo Checking "${root}/SDKs/${platform}${major}.${minor}.sdk"
        if [ -d "${root}/SDKs/${platform}${major}.${minor}.sdk" ]
        then
          SDK="${major}.${minor}"
        echo Found SDK in location "${root}/SDKs/${platform}${SDK}.sdk"
          return
        fi
      done
      #echo Checking "${root}/SDKs/${platform}${major}.sdk"
      if [ -d "${root}/SDKs/${platform}${major}.sdk" ]
      then
        SDK="${major}"
      echo Found SDK in location "${root}/SDKs/${platform}${SDK}.sdk"
        return
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
customertemplates
