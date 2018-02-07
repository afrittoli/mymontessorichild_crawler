# mymontessorychild crawler

Simple bash script to crawl images out of the pre-school web-site.

This doesn't use any stable API, it's reverse engineered from the web
site HTML to it may break at any time.

Dependencies:
* security: MacOS cli to access keychains. Used to grab the username
  and password from the login keychain
* curl, wget, tidy

Usage::

    ./get_images [TYPE] [WIDTH]
    
Available types: observations, porfolio, class

Output:
* html file: $(date +%Y%m%d)\_montessory\_${TYPE}\_${SIZE}
* image folder: images\_${SIZE}
