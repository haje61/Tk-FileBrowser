use strict;
use warnings;
use Test::More tests => 4;
use Test::Tk;
use Tk;

BEGIN {
	use_ok('Tk::FileBrowser::Header');
};

createapp;

my $hd;
if (defined $app) {
	$app->geometry('640x400+100+100');
	$hd = $app->Header(
		-text => 'Header',
	)->pack(
		-expand => 1,
		-fill => 'both',
	);
}

push @tests, (
	[ sub { return defined $hd }, 1, 'Header widget created' ],
);


starttesting;


