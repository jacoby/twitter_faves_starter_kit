# twitter_faves_starter_kit
Beginning Code to use Net::Twitter to store your Twitter Favorites 

## Prereqs

Perl Modules:
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

You will need to create both a key and secret for each application and a token and 
secret for each use and each application. [The process is explained on my blog](https://varlogrant.blogspot.com/2016/08/nettwitter-cookbook-how-i-tweet-plus.html)
and is also in [the Net::Twitter documentation](https://metacpan.org/pod/distribution/Net-Twitter/lib/Net/Twitter.pod)

If you have questions or comments, create an issue or [ask me on Twitter](https://twitter.com/jacobydave/)
