#!/bin/bash

clear
CORE_PATH="app/design/frontend"
REFERENCE_FILE="app/etc/config.php"
REFERENCE_VIEW_XML_FILE="vendor/magento/theme-frontend-blank/etc/view.xml"

# sql queries run when extending theme
MYSQL_COMMAND_1='select distinct theme_id, theme_path from theme where area="frontend"'
MYSQL_COMMAND_2='select theme_path from theme where theme_id='

# sql queries run when deleting themes
MYSQL_COMMAND_3='select count(parent_id) from theme where parent_id='
MYSQL_COMMAND_4='select theme_path, theme_title, preview_image from theme where theme_id='
MYSQL_COMMAND_5='delete from theme where theme_id='

# the script must be run from document root folder
isMagento2RootFolder () {
    if [ ! -f "$REFERENCE_FILE" ]; then
        printf "\nThe script must be run from document root!"
        exitScript
    fi
}

# get user input and create vendor folder
promptVendorName () {
    printf "\nPlease specify vendor name: "
    read -r VENDOR_NAME

    VENDOR_PATH=$CORE_PATH"/"$VENDOR_NAME

    # if vendor folder doesn't exists, create it
    if [ ! -d "$VENDOR_PATH" ]; then
        mkdir -p "$VENDOR_PATH"
        printf "Created vendor folder: %s" "$VENDOR_PATH"
    fi
}

# get user input and create theme folder
promptThemeName () {
    printf "\nPlease specify theme name: "
    read -r THEME_NAME

    THEME_PATH=$VENDOR_PATH"/"$THEME_NAME

    # if theme folder doesn't exists, create it
    if [ ! -d "$THEME_PATH" ]; then
        mkdir -p "$THEME_PATH"
        printf "Created theme folder: %s" "$THEME_PATH"
    fi
}

# process themes theme.xml file
renderThemeXmlFile () {
# check if argument has been passed to the function
if [ ! -z "$1" ] ; then
    PARENT_PATH="<parent>$1</parent>"
fi

THEME_XML_FILE=$THEME_PATH"/theme.xml"

if [ -f "$THEME_XML_FILE" ]; then
    printf "\nERROR: found: %s" "$THEME_XML_FILE"
    exitScript
else

        # get user input for theme title that will be visible in admin area
        printf "\nPlease specify theme title: "
        read -r THEME_TITLE

        THEME_XML_CONTENT='<!--
        /**
        * Copyright © 2015 Magento. All rights reserved.
        * See COPYING.txt for license details.
        */
        -->
        <theme xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="urn:magento:framework:Config/etc/theme.xsd">
        <title>'$THEME_TITLE'</title>
        '$PARENT_PATH'
        <media>
        <preview_image>media/preview.jpg</preview_image>
        </media>
        </theme>'

        # output configuration to .xml file
        echo "$THEME_XML_CONTENT" > "$THEME_XML_FILE"
        printf "Created file: %s" "$THEME_XML_FILE"
    fi
}

# process themes registration.php file
renderRegistrationPhpFile () {
    VENDOR=$VENDOR_NAME"/"$THEME_NAME
    REGISTRATION_PHP_FILE=$THEME_PATH"/registration.php"

    if [ -f "$REGISTRATION_PHP_FILE" ]; then
        printf "\nERROR: found: %s" "$REGISTRATION_PHP_FILE"
        exitScript
    else
        REGISTRATION_PHP_CONTENT="<?php
        /**
        * Copyright © 2015 Magento. All rights reserved.
        * See COPYING.txt for license details.
        */

        \Magento\Framework\Component\ComponentRegistrar::register(
            \Magento\Framework\Component\ComponentRegistrar::THEME,
            'frontend/$VENDOR',
            __DIR__
            );"

        # output configuration to .php file
        echo "$REGISTRATION_PHP_CONTENT" > "$REGISTRATION_PHP_FILE"
        printf "\nCreated file: %s" "$REGISTRATION_PHP_FILE"
    fi
}

# this function is run only when creating new theme
renderEtcViewXmlFile () {
    ETC_PATH="$THEME_PATH/etc"

    # if etc folder doesn't exists, create it
    if [ ! -d "$ETC_PATH" ]; then
        mkdir "$ETC_PATH"
        printf "\nCreated folder: %s" "$ETC_PATH"
    fi

    VIEW_XML_FILE="$ETC_PATH/view.xml"

    if [ -f "$VIEW_XML_FILE" ]; then
        printf "\nERROR: found: %s" "$VIEW_XML_FILE"
        exitScript
    else
        if [ ! -f "$REFERENCE_VIEW_XML_FILE" ] ; then
            printf "\nFile not found: $REFERENCE_VIEW_XML_FILE"
            exitScript
        fi
        # always copy view.xml file from Magento/blank theme
        cp "$REFERENCE_VIEW_XML_FILE" "$ETC_PATH"
        printf "\nCopied vendor/magento/theme-frontend-blank/view.xml to %s" "$ETC_PATH"
        printf "\nBrowse this file and customize its configuration"
    fi
}

# each new theme must have its own preview image
downloadPreviewImage () {
    IMAGE_LINK="http://inchoo.net/wp-content/uploads/2016/02/Inchoo-logo.jpg"

    MEDIA_PATH=$THEME_PATH"/media"

    # if media folder doesn't exists, create it
    if [ ! -d "$MEDIA_PATH" ]; then
        mkdir "$MEDIA_PATH"
        printf "\nCreated folder: %s" "$MEDIA_PATH"
    fi

    MEDIA_IMG=$MEDIA_PATH"/preview.jpg"
    if [ -f "$MEDIA_IMG" ]; then
        printf "\nERROR: found: %s" "$MEDIA_IMG"
        exitScript
    else
        # download image from specified link and save it into media folder
        # and rename it to preview.jpg
        wget -c -q $IMAGE_LINK -O "$MEDIA_PATH/preview.jpg"
        printf "\nDownloaded preview image to %s" "$MEDIA_PATH"
    fi
}

createInchooLessFile () {
 WEB_PATH=$THEME_PATH"/web"
    # if media folder doesn't exists, create it
    if [ ! -d "$WEB_PATH" ]; then
        mkdir "$WEB_PATH"
        printf "\nCreated folder: %s" "$WEB_PATH"
    fi

    WEB_CSS_PATH=$WEB_PATH"/css"
    if [ ! -d "$WEB_CSS_PATH" ]; then
        mkdir "$WEB_CSS_PATH"
        printf "\nCreated folder: %s" "$WEB_CSS_PATH"
    fi

    DESIGN_FILE=$WEB_CSS_PATH"/inchoo.less"
    if [ ! -f "$DESIGN_FILE" ]; then
        touch "$DESIGN_FILE"
        printf "\nCreated file: %s" "$DESIGN_FILE"
    fi

    DESIGN_FILE_CONTENT="@inchoo-green: #79AD36;
body {
    background-color: @inchoo-green !important;
}"
    echo "$DESIGN_FILE_CONTENT" > "$DESIGN_FILE"
}

promptLocale () {
    DEFAULT_LOCALE="en_US"

    printf "\nPlease specify themes locale setting or press Enter for default (en_US): "
    read -r THEME_LOCALE

    # if user did press Enter, update variable to default
    if [ -z "$THEME_LOCALE" ]; then
        THEME_LOCALE=$DEFAULT_LOCALE
        printf "Theme is using default locale: %s" "$THEME_LOCALE"
    else
        printf "Custom locale: %s" "$THEME_LOCALE"
    fi
}

updateThemeJs () {
    printf "\nIn your text editor, open the follwoing file:"
    printf "\n"
    printf "\ndev/tools/grunt/configs/themes.js"
    printf "\n"
    printf "\nand paste the following code just before the last closing curly bracket: "
    printf "\n"
    printf ",
    %s: {
        area: 'frontend',
        name: '%s',
        locale: '%s',
        files: [
        'css/inchoo'
        ],
        dsl: 'less'
    }" "$THEME_NAME" "$VENDOR" "$THEME_LOCALE"
}

displayDeploymentCommands () {
    printf "\n"
    printf "\nPlease open Magento Admin Dashboard -> Content -> Themes"
    printf "\n"
    printf "\nNow, copy and paste the following commands:"
    printf "\n"
    printf "\ngrunt clean"
    printf "\ngrunt exec:%s" "$THEME_NAME"
    printf "\nphp bin/magento cache:clean"
    printf "\nphp bin/magento setup:static-content:deploy"
    printf "\n"
    printf "\nTheme preview image is located in folder pub/media/theme/preview"
    printf "\nCompiled css file is located in folder pub/static/frontend/%s/%s/css" "$THEME_PATH" "$THEME_LOCALE"
}

updatePermissions () {
    IFS='\ ' read -r OWNER_USER OWNER_GROUP <<< "$(ls -ld "$REFERENCE_FILE" | awk '{print $3, $4}')"
    printf "\n\nSetting permissions: (%s:%s) to %s\n" "$OWNER_USER" "$OWNER_GROUP" "$THEME_PATH"
    sudo chown -R "$OWNER_USER":"$OWNER_GROUP" "$THEME_PATH"
}

# get user input for mysql credentials
promptMysqlCredentials () {
    printf "\nType in your mysql username: "
    read -r MYSQL_USERNAME

    printf "Type in your mysql password: "
    read -r -s MYSQL_PASSWORD

    printf "\nType in database name: "
    read -r MYSQL_DB_NAME
}

# define mysql connection
mysql_conn () {
    mysql -N -s -u "$MYSQL_USERNAME" -p"$MYSQL_PASSWORD" -D "$MYSQL_DB_NAME" -e "$1"
}

# perform simple mysql connection
testMysqlConnection () {
    mysql_conn "use $MYSQL_DB_NAME"

    # if error occured, the script will exit
    if [ ! "$?" = "0" ]; then
        exitScript
    fi
}

# display all available magento themes
listExistingThemes () {
    printf "\nListing existing themes:\n"

    mysql_conn "$MYSQL_COMMAND_1" | while read -r line
    do
        IFS=$'\t' read -r THEME_ID THEME_PATH <<< "$line"
        echo "[$THEME_ID, $THEME_PATH]"
    done

    printf "\nPlease, select one of the numbers: "
    read -r SELECTED_INPUT_THEME_ID

    PARENT_VENDOR=$(mysql_conn "$MYSQL_COMMAND_2$SELECTED_INPUT_THEME_ID")
}

promptAndDeleteTheme () {
    # parse sql results
    read -r HOW_MANY_CHILD_THEMES <<< "$(mysql_conn "$MYSQL_COMMAND_3$SELECTED_INPUT_THEME_ID")";

    if [ "$HOW_MANY_CHILD_THEMES" -eq 0 ] ; then
        # theme exists in database

        # parse results
        read -r THEME_PATH THEME_TITLE THEME_IMAGE<<< "$(mysql_conn "$MYSQL_COMMAND_4$SELECTED_INPUT_THEME_ID")";

        if [ -n "$THEME_TITLE" ] ; then
            # theme is not parent theme, it is safe to remove it

            # remove theme folder and its files
            printf "\nDeleting theme files in: %s/%s" "$CORE_PATH" "$THEME_PATH"
            rm -rf "$CORE_PATH"/"$THEME_PATH"

            if [ ! -z $THEME_IMAGE ] ; then
                printf "\nDeleting theme preview image in pub/media/theme/preview/%s" "$THEME_IMAGE"
                PUB_THEME_IMAGE="pub/media/theme/preview/$THEME_IMAGE"
                rm "$PUB_THEME_IMAGE"
            fi

            # remove theme entry in database
            printf "\nDeleting database entry in table 'theme'"
            mysql_conn "$MYSQL_COMMAND_5$SELECTED_INPUT_THEME_ID"

            # notify user to delete content in grunts theme.js file
            IFS='/' read -a DB_THEME_PATH <<< "$THEME_PATH"
            printf "\n\nIn your text editor, open the following file:"
            printf "\ndev/tools/grunt/configs/themes.js"
            printf "\nand delete content that is related to key '%s'" "${DB_THEME_PATH[1]}"

            printf "\n\nDone"
        else
            # row entry in database table does not exist
            printf "\nERROR - theme with [theme_id, %s] is not found in database!" "$SELECTED_INPUT_THEME_ID"
            exitScript
        fi
    else
        # theme is parent theme, do nothing
        echo "Cannot delete $PARENT_VENDOR, theme is parent to total of $HOW_MANY_CHILD_THEMES theme(s)!"
        exitScript
    fi
}

createNewTheme () {
    promptVendorName
    promptThemeName
    renderThemeXmlFile
    promptLocale
    renderRegistrationPhpFile
    renderEtcViewXmlFile
    downloadPreviewImage
    createInchooLessFile
    updatePermissions
    updateThemeJs
    displayDeploymentCommands
}

extendExistingTheme () {
    promptMysqlCredentials
    testMysqlConnection
    listExistingThemes
    promptVendorName
    promptThemeName
    renderThemeXmlFile "$PARENT_VENDOR"
    promptLocale
    renderRegistrationPhpFile
    downloadPreviewImage
    createInchooLessFile
    updatePermissions
    updateThemeJs
    displayDeploymentCommands
}

deleteTheme () {
    promptMysqlCredentials
    testMysqlConnection
    listExistingThemes
    promptAndDeleteTheme
}

exitScript () {
    echo " "
    echo "The script is going to exit"
    exit
}

# this is where script output starts
printf "*********** Magento2 Theme Manager ***********"

isMagento2RootFolder

printf "\nWould you like to:"
printf "\n1) create a new theme"
printf "\n2) create a child theme"
printf "\n3) delete a theme"
printf "\nPlease, enter your option: "
read -r THEME_OPTION

# : '
case "$THEME_OPTION" in
    1 ) createNewTheme ;;
2 ) extendExistingTheme ;;
3 )	deleteTheme ;;
* )	printf "\nUnknown argument specified: %s" "$THEME_OPTION"
exitScript ;;
esac
#'

echo " "
echo "*********** Magento2 Theme Manager has finished successfully ***********"