prepare_extra_files () {
    # ### write out extra files from env
    if test "$APPLIANCE_EXTRA_FILES_LEN" != ""; then
        for i in $(seq 0 $(( $APPLIANCE_EXTRA_FILES_LEN -1 )) ); do
            fieldname="APPLIANCE_EXTRA_FILES_${i}_PATH"; fname="${!fieldname}"
            fieldname="APPLIANCE_EXTRA_FILES_${i}_OWNER"; fowner="${!fieldname}"
            fieldname="APPLIANCE_EXTRA_FILES_${i}_PERMISSIONS"; fperm="${!fieldname}"
            fieldname="APPLIANCE_EXTRA_FILES_${i}_CONTENT"; fcontent="${!fieldname}"
            echo "$fcontent" > $fname
            if test "$fowner" != ""; then chown $fowner $fname; fi
            if test "$fperm" != ""; then chmod $fperm $fname; fi
        done
    fi
}
