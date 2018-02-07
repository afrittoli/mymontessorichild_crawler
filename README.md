# mymontessorychild crawler

Simple bash script to crawl images out of the pre-school web-site.

This doesn't use any stable API, it's reverse engineered from the web
site HTML to it may break at any time.

Dependencies:
* security: MacOS cli to access keychains. Used to grab the username
  and password from the login keychain
* curl, wget, tidy

Security Note:

Username and password are taken for security from the logic keychain.
Depending on local setting running the script may prompt for a password
to unlock the keychain.

Usage:

    ./get_images [TYPE] [WIDTH]
    
Available types: observations, porfolio, class.
Width in number of pixels.

Example:

    ./get_images observations 1200

Output:
* html file: $(date +%Y%m%d)\_montessory\_${TYPE}\_${SIZE}
* image folder: images\_${SIZE}
