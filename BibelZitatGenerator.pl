#!/usr/bin/env perl
use Mojolicious::Lite;

use utf8;

# connect to database
use DBI;
my $dbh = DBI->connect("dbi:SQLite:Luther_1912.sqlite","","", {sqlite_unicode => 1}) or die "Could not connect";

my %replacement = (
  '(\s)HERR([\s,.])' => '" 1 HERR$2"',
  '(\s)HERRN([\s,.])' => '" 1 HERRN$2"',
  'Jesus'=> [
    '"dieser 1 Dude"',
    '"dieser Messias Brudi"',
  ]
  ,
  'eure' => '"euch Ihre"',
#  '(\s)Gott(\s)' => '"$1Got$2"',
  '(\s)Königs([\s,.])' => '"$1Kronendudes$2"',
  '(\s)Könige([\s,.])' => '"$1Kronendudes$2"',
  '(\s)König([\s,.])' => '"$1Kronendude$2"',
  'Propheten' => '"Profeten"',
  '(\s)Vater(\s)' => '"$1Babo$2"',
  '(\s)Väter(\s)' => '"$1Babos$2"',
  '(\s)Mann(\s)' => '"$1Dude$2"',
  '(\s)Bruder(\s)' => '"$1Brudi$2"',
  '(\s)Brüder(\s)' => '"$1Brudis$2"',
#  '(\s)er(\s)' => '"$1dieser Messias Brudi$2"',
#  '(\s)wird(\s)([^\s]+)' => '"$1wird$2am $3 been"'
);

# add helper methods for interacting with database
helper db => sub { $dbh };
helper replacement => sub { state $get = \%replacement };

# Documentation browser under "/perldoc"
plugin 'PODRenderer';

get '/' => sub {
  my $c = shift;
  $c->render(template => 'index');
};

get '/get' => sub {
  my $c = shift;

  my $sth = eval { $c->db->prepare('SELECT v.text, v.chapter, v.verse, b.name FROM verse v LEFT JOIN book b ON b.id = v.book_id ORDER BY RANDOM() LIMIT 1') } || return undef;
  $sth->execute;

  my $resultarray = $sth->fetchall_arrayref->[0];
  my ($text, $chapter, $verse, $book) = @{$resultarray};

  for my $replacement (keys %{$c->replacement}) {
    if(ref($c->replacement->{$replacement}) eq 'ARRAY') {
      $text =~ s/$replacement/$c->replacement->{$replacement}->[rand(scalar(@{$c->replacement->{$replacement}}))]/gee;
    } else {
      $text =~ s/$replacement/$c->replacement->{$replacement}/gee;
    }
  }

  $c->render(json => { 
    'text' => $text,
    'chapter'=> $chapter,
    'verse'=> $verse,
    'book'=> $book
  });
};

app->start;
