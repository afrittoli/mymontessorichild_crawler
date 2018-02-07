#!/bin/bash

TYPE=${1:-observations}
SIZE=${2:-800}
OUTPUT=${3:-.}

if [ "$1" == "help" ]; then
    echo -e "\nUsage: ./get_images [TYPE] [WIDTH] [OUTPUT]"
    echo -e "\nAvailable types: observations, porfolio, class\n"
    exit 0
fi

# Log something
function log_nice {
  echo "$(date +%Y%m%d) [$TYPE][$SIZE] $*"
}

if [ ! -d $OUTPUT ]; then
    mkdir $OUTPUT
fi
log_nice "Generating content in $OUTPUT"

# Get a Session Cookie
MONTESSORI_DOMAIN=www.mymontessorichild.com
MONTESSORI_URL=https://${MONTESSORI_DOMAIN}/parents
MONTESSORI_USER=$(security find-internet-password -s $MONTESSORI_DOMAIN | sed -n 's/^.*"acct"<blob>="\(.*\)"$/\1/p')
MONTESSORI_PASSWORD=$(security find-internet-password -g -s $MONTESSORI_DOMAIN -w)
COOKIE_PHPSESSID=$(curl -s --include Set-Cookie ${MONTESSORI_URL}/index.php?action=login --data "un=${MONTESSORI_USER}" --data "pw=${MONTESSORI_PASSWORD}" | sed -n 's/^.*PHPSESSID=\(.*\); e.*$/\1/p' | tail -1)

if [ -z $COOKIE_PHPSESSID ]; then
  log_nice "Could not get a session ID" >&2
  exit 2
fi

log_nice "Got a PHP Session ID: $COOKIE_PHPSESSID"

# Setup variables
FULL_URL=$MONTESSORI_URL'/data.php?mode=history&data='$TYPE
IMAGE_URL=$MONTESSORI_URL'/image.php?diary='
WGET="/usr/local/bin/wget --header 'Cookie: PHPSESSID=$COOKIE_PHPSESSID'"
TARGET_BASE="$(date +%Y%m%d)_montessori_${TYPE}_${SIZE}"
IMAGE_BASE="images_${SIZE}"
STD_SIZE=180
STD_WIDE_SIZE=235
RESIZE_WIDE_SIZE=$(( SIZE * STD_WIDE_SIZE / STD_SIZE ))

# Initial setup: create the header fragment, ensure the image folder exists
sed -e 's/__MAX_WIDTH__/'$SIZE'/g' header.html_fragment > /tmp/header.html_fragment

if [ ! -d $OUTPUT/$IMAGE_BASE ]; then
    mkdir $OUTPUT/$IMAGE_BASE
fi

# Get the main content page and build the full page
eval $WGET '$FULL_URL' -O- 2>/dev/null | sed -e "s/ type=\"activity\"//g" -e "s/image.php?diary=\([0-9]*\)\"/$IMAGE_BASE\/\1.jpg\" alt=\"\1\"/g" > /tmp/_${TYPE}.html
cat /tmp/header.html_fragment /tmp/_${TYPE}.html footer.html_fragment | tidy -q -w 500 > $OUTPUT/$TARGET_BASE.html

log_nice "HTML page in $OUTPUT/$TARGET_BASE.html"

function get_image_if_new {
  _img="$1"
  _img_url="$2"
  if [ ! -f $TARGET_BASE/${_img}.jpg ]; then
      eval $WGET '${_img_url}' -O$OUTPUT/$IMAGE_BASE/${_img}.jpg &> /dev/null
      log_nice "New image $OUTPUT/$IMAGE_BASE/${_img}.jpg"
  fi
}

# Get all square images
sed -n 's/^.*class="square".*alt="\([0-9]*\)".*$/\1/p' $OUTPUT/$TARGET_BASE.html | while read aa; do
    aa_IMAGE_URL="${IMAGE_URL}${aa}&w=${SIZE}&h=${SIZE}"
    get_image_if_new "$aa" "$aa_IMAGE_URL"
done

# Get all portrait images
sed -n 's/^.*class="portrait".*alt="\([0-9]*\)".*$/\1/p' $OUTPUT/$TARGET_BASE.html | while read aa; do
    aa_IMAGE_URL="${IMAGE_URL}${aa}&h=${SIZE}&w=${RESIZE_WIDE_SIZE}"
    get_image_if_new "$aa" "$aa_IMAGE_URL"
done

# Get all landscape images
sed -n 's/^.*class="landscape".*alt="\([0-9]*\)".*$/\1/p' $OUTPUT/$TARGET_BASE.html | while read aa; do
    aa_IMAGE_URL="${IMAGE_URL}${aa}&h=${RESIZE_WIDE_SIZE}&w=${SIZE}"
    get_image_if_new "$aa" "$aa_IMAGE_URL"
done
