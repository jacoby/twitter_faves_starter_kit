# twitter_faves_starter_kit
Beginning Code to use Net::Twitter to store your Twitter Favorites 

## Prereqs

* Carp 
* Data::Dumper 
* DateTime 
* Encode 
* Getopt::Long 
* IO::Interactive
* LWP::UserAgent 
* Net::Twitter 
* WWW::Shorten 
* YAML 

## Manifest
  + twitter_favorites_harvester.pl
  + twitter_favorites.pl
  + twitter_favorites.sql

## Usage
    4-23 0 * * *                /home/jacoby/bin/twitter_favorites.pl -u jacobydave
    0    0 * * *                /home/jacoby/bin/twitter_favorites_harvester.pl -u jacobydave

twitter_favorites will go until it sees an already-favorited tweet. 
twitter_favorites_harvester, in contrast, will keep going. Both use a timeout
after each chunk to keep from hitting the rate limit. 

My code uses a custom database interface called oDB, which is optimized for
connecting to MySQL. I should change this so that it uses DBIx::Class, but as
this is hobby code, I wouldn't hold my breath.

twitter_favorites.sql shows the database schema used by my code.
