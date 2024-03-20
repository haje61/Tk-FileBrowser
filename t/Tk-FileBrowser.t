use strict;
use warnings;
use Test::More tests => 7;
use Test::Tk;
use Tk;

BEGIN {
	use_ok('Tk::FileBrowser::Header');
	use_ok('Tk::FileBrowser')
};

createapp;

my $fb;
if (defined $app) {
	$app->geometry('640x400+100+100');
	$fb = $app->FileBrowser(
		-columns => [qw[Size Modified Accessed Created]],
	)->pack(
		-expand => 1,
		-fill => 'both',
	);
#	$fb->autosetmode;
	my $entry = 'home';
	my $t = $fb->Subwidget('Tree');
#	print "subjwidget not found\n" unless defined $t;
#	$fb->add($entry);
#	$t->itemCreate($entry, 0, -text => $entry);
}

push @tests, (
	[ sub { return defined $fb }, 1, 'FileBrowser widget created' ],
	[ sub { return defined $fb->Subwidget('Tree') }, 1, 'Tree widget found' ],
	[ sub { $fb->load; return 1 }, 1, 'Loaded current directory' ],
);


starttesting;





