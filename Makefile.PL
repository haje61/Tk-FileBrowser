use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'FileBrowser';
my $ld = '$(INST_LIBDIR)';

WriteMakefile(
	NAME => "Tk::$pm",
	PREREQ_PM => {
	},
	ABSTRACT_FROM => "lib/Tk/$pm.pm",
	VERSION_FROM => "lib/Tk/$pm.pm",
	AUTHOR => 'Hans Jeuken <hanje at cpan dot org>',
	LICENSE	=> 'perl',
	(eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => "git://github.com/haje61/Tk-$pm.git",
				web  => "https://github.com/haje61/Tk-$pm",
			},
		}}) : ()
	),
);


