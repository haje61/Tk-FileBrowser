use strict;
use warnings;
use Test::More tests => 7;
use Test::Tk;
use Tk;

BEGIN {
	use_ok('Tk::FileBrowser::Header');
	use_ok('Tk::FileBrowser')
};

$delay = 1000;

createapp;

my $fb;
if (defined $app) {
	$app->geometry('640x400+100+100');
	$fb = $app->FileBrowser(
		-columns => [qw[Size Modified Created Accessed]],
		-selectmode => 'extended',
#		-sorton => 'Modified',
		-sorton => 'Size',
#		-sortorder => 'ascending',
		-invokefile => sub { my $f = shift; print "invoking: $f\n" },
	)->pack(
		-expand => 1,
		-fill => 'both',
	);
}

push @tests, (
	[ sub { return defined $fb }, 1, 'FileBrowser widget created' ],
	[ sub { return defined $fb->Subwidget('Tree') }, 1, 'Tree widget found' ],
	[ sub { $fb->load; return 1 }, 1, 'Loaded current directory' ],
);


starttesting;












