#!/bin/bash

TYPE=${1:-observations}
SIZE=${2:-800}
OUTPUT=${3:-.}

if [ "$1" == "help" ]; then
    echo -e "\nUsage: ./get_images [TYPE] [WIDTH] [OUTPUT]"
    echo -e "\nAvailable types: observations, porfolio, class\n"
    exit 0
fi

# Get a Session Cookie
MONTESSORI_DOMAIN=www.mymontessorichild.com
MONTESSORI_URL=https://${MONTESSORI_DOMAIN}/parents
MONTESSORI_USER=$(security find-internet-password -s $MONTESSORI_DOMAIN | sed -n 's/^.*"acct"<blob>="\(.*\)"$/\1/p')
MONTESSORI_PASSWORD=$(security find-internet-password -g -s $MONTESSORI_DOMAIN -w)
COOKIE_PHPSESSID=$(curl -s --include Set-Cookie ${MONTESSORI_URL}/index.php?action=login --data "un=${MONTESSORI_USER}" --data "pw=${MONTESSORI_PASSWORD}" | sed -n 's/^.*PHPSESSID=\(.*\); e.*$/\1/p' | tail -1)

# Setup variables
FULL_URL=$MONTESSORI_URL'/data.php?mode=history&data='$TYPE
IMAGE_URL=$MONTESSORI_URL'/image.php?diary='
WGET="wget --header 'Cookie: PHPSESSID=$COOKIE_PHPSESSID'"
TARGET_BASE="$(date +%Y%m%d)_montessori_${TYPE}_${SIZE}"
IMAGE_BASE="images_${SIZE}"
STD_SIZE=180
STD_WIDE_SIZE=235
RESIZE_WIDE_SIZE=$(( SIZE * STD_WIDE_SIZE / STD_SIZE ))

# Initial setup: create the header fragment, ensure the image folder exists
sed -e 's/__MAX_WIDTH__/'$SIZE'/g' header.html_fragment > /tmp/header.html_fragment

if [ ! -d $IMAGE_BASE ]; then
    mkdir $IMAGE_BASE
fi

# Get the main content page and build the full page
eval $WGET '$FULL_URL' -O- 2>/dev/null | sed -e "s/ type=\"activity\"//g" -e "s/image.php?diary=\([0-9]*\)\"/$IMAGE_BASE\/\1.jpg\" alt=\"\1\"/g" > /tmp/_${TYPE}.html
cat /tmp/header.html_fragment /tmp/_${TYPE}.html footer.html_fragment | tidy -q -w 500 > $OUTPUT/$TARGET_BASE.html

# Get all square images
sed -n 's/^.*class="square".*alt="\([0-9]*\)".*$/\1/p' $TARGET_BASE.html | while read aa; do
    aa_IMAGE_URL="${IMAGE_URL}${aa}&w=${SIZE}&h=${SIZE}"
    if [ ! -f $TARGET_BASE/${aa}.jpg ]; then
        eval $WGET '$aa_IMAGE_URL' -O$OUTPUT/$IMAGE_BASE/${aa}.jpg &> /dev/null
    fi
done

# Get all portrait images
sed -n 's/^.*class="portrait".*alt="\([0-9]*\)".*$/\1/p' $TARGET_BASE.html | while read aa; do
    aa_IMAGE_URL="${IMAGE_URL}${aa}&h=${SIZE}&w=${RESIZE_WIDE_SIZE}"
    if [ ! -f $TARGET_BASE/${aa}.jpg ]; then
        eval $WGET '$aa_IMAGE_URL' -O$OUTPUT/$IMAGE_BASE/${aa}.jpg &> /dev/null
    fi
done

# Get all landscape images
sed -n 's/^.*class="landscape".*alt="\([0-9]*\)".*$/\1/p' $TARGET_BASE.html | while read aa; do
    aa_IMAGE_URL="${IMAGE_URL}${aa}&h=${RESIZE_WIDE_SIZE}&w=${SIZE}"
    if [ ! -f $TARGET_BASE/${aa}.jpg ]; then
        eval $WGET '$aa_IMAGE_URL' -O$OUTPUT/$IMAGE_BASE/${aa}.jpg &> /dev/null
    fi
done
