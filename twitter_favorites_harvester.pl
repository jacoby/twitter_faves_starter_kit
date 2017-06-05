#!/usr/bin/env perl

use feature qw{ say } ;
use strict ;
use utf8 ;
binmode STDOUT, ':utf8' ;

use Carp ;
use Data::Dumper ;
use DateTime ;
use Encode 'decode' ;
use Getopt::Long ;
use IO::Interactive qw{ interactive } ;
use LWP::UserAgent ;
use Net::Twitter ;
use WWW::Shorten 'TinyURL' ;
use YAML qw{ DumpFile LoadFile } ;

use lib '/home/jacoby/lib' ;
use DB ;
use oDB ;

my $db = oDB->new('itap') ;
my $config = config() ;
read_favorites($config) ;
exit ;

# ========= ========= ========= ========= ========= ========= =========
sub read_favorites {
    my $config = shift ;
    my $twit   = Net::Twitter->new(
        consumer_key    => $config->{consumer_key},
        consumer_secret => $config->{consumer_secret},
        ssl             => 1,
        traits          => [qw/API::RESTv1_1/],
        ) ;
    if ( $config->{access_token} && $config->{access_token_secret} ) {
        $twit->access_token( $config->{access_token} ) ;
        $twit->access_token_secret( $config->{access_token_secret} ) ;
        }
    unless ( $twit->authorized ) {
        croak("Not Authorized") ;
        }

    # my @favs;
    for ( my $page = $config->{start}; $page <= $config->{end}; ++$page ) {
        say {interactive} qq{\tPAGE $page} ;
        my $r = $twit->favorites(
            {   page  => $page,
                count => 200,
                }
            ) ;
        last unless @$r ;

        # push @favs , @$r ;
        for my $fav (@$r) {
            if ( $config->{verbose} ) {
                say {interactive} handle_date( $fav->{created_at} ) ;
                }
            store_tweet( $config->{user}, $fav ) ;
            }
        sleep 60 * 3 ;    # five minutes
        }
    }

# ========= ========= ========= ========= ========= ========= =========
sub store_tweet {
    my $consumer = shift ;
    my $tweet    = shift ;
    my $sql      = <<SQL;
    INSERT INTO twitter_favorites (
        consumer ,
        twitter_id , text , created , retweeted ,
        user_id , user_name , user_screen_name
        )
    VALUES (
        ? ,
        ? , ? , ? , ? ,
        ? , ? , ?
        ) ;
SQL
    my @input ;
    push @input, $consumer ;
    push @input, $tweet->{id} ;                           # twitter_id
    push @input, $tweet->{text} ;                         # text
    push @input, handle_date( $tweet->{created_at} ) ;    # created
    push @input, $tweet->{truncated} ;                    # retweeted
    push @input, $tweet->{user}->{id} ;                   # user id
    push @input, $tweet->{user}->{name} ;                 # user id
    push @input, $tweet->{user}->{screen_name} ;          # user id

    my $test = test_database( $tweet->{id} ) ;

    if ( !$test ) {
        my $r = $db->do( $sql, { placeholders => [@input] } ) ;
        say {interactive} $tweet->{id} ;
        }
    else {
        #say { interactive } join "\t", '', 'done' ;
        }
    }

# ========= ========= ========= ========= ========= ========= =========
sub test_database {
    my $tweet_id = shift ;
    my $sql      = <<SQL;
        SELECT COUNT(*) FROM twitter_favorites WHERE twitter_id = ?
SQL
    my $c = $db->arrayref( $sql, { placeholders => [$tweet_id] } ) ;
    return $c->[0][0] ;
    }

# ========= ========= ========= ========= ========= ========= =========
# Gets DM date, for comparison
sub handle_date {
    my $twitter_date = shift ;
    my $months       = {
        Jan => 1,
        Feb => 2,
        Mar => 3,
        Apr => 4,
        May => 5,
        Jun => 6,
        Jul => 7,
        Aug => 8,
        Sep => 9,
        Oct => 10,
        Nov => 11,
        Dec => 12,
        } ;
    my @twitter_date = split m{\s+}, $twitter_date ;
    my $year         = $twitter_date[5] ;
    my $month        = $months->{ $twitter_date[1] } ;
    my $day          = $twitter_date[2] ;
    my $t_day        = DateTime->new(
        year      => $year,
        month     => $month,
        day       => $day,
        time_zone => 'floating'
        ) ;
    return $t_day->ymd() ;
    }

#========= ========= ========= ========= ========= ========= =========
sub config {
    my $config_file = $ENV{HOME} . '/.twitter_dm.cnf' ;
    my $data        = LoadFile($config_file) ;

    my $config ;
    $config->{start} = 0 ;
    $config->{end}   = 200 ;

    GetOptions(
        'user=s'  => \$config->{user},
        'start=s' => \$config->{start},
        'end=s'   => \$config->{end},
        'help'    => \$config->{help},
        'verbose' => \$config->{verbose},
        ) ;

    #$config->{ user } = 'jacobydave' ;
    if (   $config->{help}
        || !$config->{user}
        || $config->{start} > $config->{end}
        || !$data->{tokens}->{ $config->{user} } ) {
        say $config->{user} || 'no user' ;
        croak qq(nothing) ;
        }

    for my $k (qw{ consumer_key consumer_secret }) {
        $config->{$k} = $data->{$k} ;
        }

    my $tokens = $data->{tokens}->{ $config->{user} } ;
    for my $k (qw{ access_token access_token_secret }) {
        $config->{$k} = $tokens->{$k} ;
        }
    return $config ;
    }

#========= ========= ========= ========= ========= ========= =========
sub restore_tokens {
    my ($user) = @_ ;
    my ( $access_token, $access_token_secret ) ;
    if ( $config->{tokens}{$user} ) {
        $access_token        = $config->{tokens}{$user}{access_token} ;
        $access_token_secret = $config->{tokens}{$user}{access_token_secret} ;
        }
    return $access_token, $access_token_secret ;
    }

#========= ========= ========= ========= ========= ========= =========
sub save_tokens {
    my ( $user, $access_token, $access_token_secret ) = @_ ;
    $config->{tokens}{$user}{access_token}        = $access_token ;
    $config->{tokens}{$user}{access_token_secret} = $access_token_secret ;

    #DumpFile( $config_file, $config ) ;
    return 1 ;
    }
