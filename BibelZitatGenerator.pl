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
  my $text = $resultarray->[0];
  my $chapter = $resultarray->[1];
  my $verse = $resultarray->[2];
  my $book = $resultarray->[3];

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
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
<body ng-app="myapp">

<div class="site-wrapper">
  <div class="site-wrapper-inner">
    <div class="cover-container">

      <div class="inner cover" ng-controller="MyController" >
        <!-- <h1 class="cover-heading">Full screen background cover page.</h1> -->

        <p class="lead">
            {{myData.fromServer}}
        </p>

        <p class="lead"><button class="btn btn-lg btn-info" ng-click="myData.doClick(item, $event)">Generiere</button></p>
      </div>

      <div class="mastfoot">
        <div class="inner">
          <!-- Validation -->
          
        </div>
      </div>
    </div>
</div>
</div>

  <script>
    angular.module("myapp", [])
        .controller("MyController", function($scope, $http) {
            $scope.myData = {};
            $scope.myData.doClick = function(item, event) {

                var responsePromise = $http.get("/get", {
			headers: {
        			'Content-Type': 'application/json; charset=UTF-8'
    			}
		});

                responsePromise.success(function(data, status, headers, config) {
                    //$scope.myData.fromServer = data.text + ' - ' + data.book + ', ' + data.chapter + ', ' + data.verse;
                    $scope.myData.fromServer = data.text;
                });
                responsePromise.error(function(data, status, headers, config) {
                    alert("AJAX failed!");
                });
            }


        } );
  </script>

</body>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these tags -->
    <script src="http://ajax.googleapis.com/ajax/libs/angularjs/1.4.8/angular.min.js"></script>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" integrity="sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7" crossorigin="anonymous">
    <style>

/* Links */
a,
a:focus,
a:hover {
  color: #fff;
}

/* Custom default button */
.btn-default,
.btn-default:hover,
.btn-default:focus {
  color: #333;
  text-shadow: none; /* Prevent inheritence from `body` */
  background-color: #fff;
  border: 1px solid #fff;
}


/*
 * Base structure
 */

html,
body {
/*css for full size background image*/
  background: url(http://121clicks.com/wp-content/uploads/2012/08/beautiful_landscape_best_08.jpg) no-repeat center center fixed; 
  -webkit-background-size: cover;
  -moz-background-size: cover;
  -o-background-size: cover;
  background-size: cover;
  
  height: 100%;
  background-color: #060;
  color: #fff;
  text-align: center;
  text-shadow: 0 1px 3px rgba(0,0,0,.5);
 
}

/* Extra markup and styles for table-esque vertical and horizontal centering */
.site-wrapper {
  display: table;
  width: 100%;
  height: 100%; /* For at least Firefox */
  min-height: 100%;
  -webkit-box-shadow: inset 0 0 100px rgba(0,0,0,.5);
          box-shadow: inset 0 0 100px rgba(0,0,0,.5);
}
.site-wrapper-inner {
  display: table-cell;
  vertical-align: top;
}
.cover-container {
  margin-right: auto;
  margin-left: auto;
}

/* Padding for spacing */
.inner {
  padding: 30px;
}


/*
 * Header
 */
.masthead-brand {
  margin-top: 10px;
  margin-bottom: 10px;
}

.masthead-nav > li {
  display: inline-block;
}
.masthead-nav > li + li {
  margin-left: 20px;
}
.masthead-nav > li > a {
  padding-right: 0;
  padding-left: 0;
  font-size: 16px;
  font-weight: bold;
  color: #fff; /* IE8 proofing */
  color: rgba(255,255,255,.95);
  border-bottom: 2px solid transparent;
}
.masthead-nav > li > a:hover,
.masthead-nav > li > a:focus {
  background-color: transparent;
  border-bottom-color: #a9a9a9;
  border-bottom-color: rgba(255,255,255,.25);
}
.masthead-nav > .active > a,
.masthead-nav > .active > a:hover,
.masthead-nav > .active > a:focus {
  color: #fff;
  border-bottom-color: #fff;
}

@media (min-width: 768px) {
  .masthead-brand {
    float: left;
  }
  .masthead-nav {
    float: right;
  }
}

.cover {
  padding: 0 20px;
}
.cover .btn-lg {
  padding: 10px 20px;
  font-weight: bold;
}

.mastfoot {
  color: #999; /* IE8 proofing */
  color: rgba(255,255,255,.5);
}

@media (min-width: 768px) {
  /* Pull out the header and footer */
  .masthead {
    position: fixed;
    top: 0;
  }
  .mastfoot {
    position: fixed;
    bottom: 0;
  }
  /* Start the vertical centering */
  .site-wrapper-inner {
    vertical-align: middle;
  }
  /* Handle the widths */
  .masthead,
  .mastfoot,
  .cover-container {
    width: 100%; /* Must be percentage or pixels for horizontal alignment */
  }
}

@media (min-width: 992px) {
  .masthead,
  .mastfoot,
  .cover-container {
    width: 700px;
  }
}

    </style>
    <title><%= title %></title></head>
  <%= content %>
</html>
