package Tk::FileBrowser;

=head1 NAME

Tk::FileBrowser - Multi column file system explorer

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = 0.01;

use base qw(Tk::Derived Tk::Frame);
Construct Tk::Widget 'FileBrowser';

use Config;
use Cwd;
use File::Basename;
require Tk::ITree;
require Tk::FileBrowser::Header;

my %timedata = (
	Accessed => 'atime',
	Created => 'ctime',
	Modified => 'mtime',
);

=head1 SYNOPSIS

 require Tk::FileBrowser;
 my $b = $window->FileBrowser(@options)->pack;
 $b->load($folder);

=head1 DESCRIPTION

A multicolumn file browser widget. Columns are configurable, sortable
and resizable.

=head1 CONFIG VARIABLES

=over 4

=item Switch: B<-casedependantsort>

Default value 0;

If change the value you have to call B<refresh> to see your changes.

=item Switch: B<-columns>

Specify a list of column names to display. Only available at create
time. Allowed values are 'Accessed', 'Created', 'Modified' and 'Size'.

Default value ['Modified', 'Size'].

The 'Name' column is always present and always first.

=item Switch: B<-directoriesfirst>

Default value 1.

If change the value you have to call B<refresh> to see your changes.

=item Switch: B<-diriconcall>

Callback for obtaining the dir icon. By default it is set
to a call that returns the default folder.xpm in the Perl/Tk
distribution.

=item Switch: B<-fileiconcall>

Callback for obtaining the file icon. By default it is set
to a call that returns the default file.xpm in the Perl/Tk
distribution.

=item Switch: B<-showhidden>

Default value 0;

If change the value you have to call B<load> again to see your changes.

=back

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self,$args) = @_;

	my $columns = delete $args->{'-columns'};
	$columns = ['Size', 'Modified'] unless defined $columns;

	$self->SUPER::Populate($args);
	
	my $mnutxt = '';
	$self->{BASE} = undef;
	$self->{COLNAMES} = {};
	$self->{COLNUMS} = {};
	$self->{MENUTXT} = \$mnutxt,
	$self->{POOL} = {};
	$self->{SORTON} = 'Name';
	$self->{SORTORDER} = 'ascending';

	my $toolframe = $self->Frame->pack(-fill => 'x');
	my $mbutton = $toolframe->Menubutton(
		-anchor => 'w',
		-textvariable => \$mnutxt,
	)->pack(-side => 'left', -expand => 1, -fill => 'x');
	$self->Advertise('UpMenu', $mbutton);

	my $tree = $self->CreateTreeWidget(@$columns);
	
	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDANTS'],
		-casedependantsort => ['PASSIVE', undef, undef, 0],
		-columns => ['PASSIVE', undef, undef, $columns],
		-directoriesfirst => ['PASSIVE', undef, undef, 1],
		-diriconcall => ['CALLBACK', undef, undef, ['DefaultDirIcon', $self]],
		-fileiconcall => ['CALLBACK', undef, undef, ['DefaultFileIcon', $self]],
		-invokefile => ['CALLBACK', undef, undef, sub {}],
		-showhidden => ['PASSIVE', undef, undef, 0],
		DEFAULT => [ $tree ],
	);
	return $self;
}

sub AddItem {
	my ($self, $path, $name, $data) = @_;

	my $item = $name;
	$item = "$path/$name" unless $path eq ''; # TODO separator for MSWin32
	my @op = (-itemtype => 'imagetext',);
	if ($self->IsDir($item)) {
		push @op, -image => $self->GetDirIcon($item);
	} else {
		push @op, -image => $self->GetFileIcon($item);
	}
	my @entrypos = $self->Position($item, $data);
	$self->add($item, -data => $data, @entrypos);
	my $c = $self->cget('-columns');
	my @columns = ('Name', @$c);
	for (@columns) {
		my $col_name = $_;
		my $col_num = $self->{COLNAMES}->{$col_name};
		if ($col_name eq 'Name') {
			$self->itemCreate($item, $col_num, @op,
				-text => $name,
			);
		} elsif (exists $timedata{$col_name}) {
			my $tag = $timedata{$col_name};
			my $time = $data->{$tag};
			if (defined $time) {
				$time = scalar localtime $time;
				$self->itemCreate($item, $col_num,
					-text => $time,
				);
			}
		} elsif ($col_name eq 'Size') {
			$self->itemCreate($item, $col_num,
				-text => $self->GetSizeString($data),
			);
		}
	}
	$self->autosetmode;
	if ($self->IsDir($item) and ($data->{'loaded'})) {
		my $c = $data->{'children'};
		for (sort keys %$c) {
			$self->AddItem($item, $_, $c->{$_});
		}
		$self->close($item) unless $data->{'open'};
	}
}

sub ColName {
	my ($self, $num) = @_;
	return $self->{COLNUMS}->{$num}
}

sub ColNum {
	my ($self, $name) = @_;
	return $self->{COLNAMES}->{$name}
}

sub ColumnResize {
	my ($self, $column, $size) = @_;
	$self->columnWidth($column, $size);
}

sub CreateTreeWidget {
	my ($self, @columns) = @_;
	unshift @columns, 'Name';
	my $tree = $self->Subwidget('Tree');
	my $col_names = $self->{COLNAMES};
	my $col_nums = $self->{COLNUMS};
	if (defined $tree) {
		$tree->destroy;
		$col_names = {};
		$col_nums = {};
	}
	my $num_col = @columns;
	my $sep = '/';
	$sep = '\\' if $Config{osname} eq 'MSWin32';
	$tree = $self->Scrolled('ITree',
		-separator => $sep,
		-columns => $num_col,
		-command => ['Invoke', $self],
		-header => 1,
		-indicatorcmd => ['IndicatorPressed', $self],
		-scrollbars => 'osoe',
	)->pack(
		-padx => 2, 
		-pady => 2,
		-expand => 1, 
		-fill => 'both',
	);
	$self->Advertise(Tree => $tree);
	my $column = 0;
	for (@columns) {
		my $n = $column;
		my $item = $_;
		my @so = ();
		@so = (-sortorder => 'ascending') if $column eq 0;
		$col_names->{$item} = $n;
		$col_nums->{$n} = $item;
		my $header = $tree->Header(@so,
			-sortcall => ['SortMode', $self],
			-resizecall => ['ColumnResize', $self, $n],
			-text => $_
		);
		$tree->headerCreate($column, -itemtype => 'window', -widget => $header);
		$column ++;
	}
	$self->{COLNAMES} = $col_names;
	$self->{COLNUMS} = $col_nums;
	$self->Delegates(
		DEFAULT => $tree,
	);
	return $tree
}

sub DefaultDirIcon {
	return $_[0]->Pixmap(-file => Tk->findINC('folder.xpm'))
}

sub DefaultFileIcon {
	return $_[0]->Pixmap(-file => Tk->findINC('file.xpm'))
}

sub folderRead {
	my ($self, $folder, $recurse) = @_;
	$recurse = 1 unless defined $recurse;
	my $dh;
	unless (opendir($dh, $folder)) {
		warn "cannot open folder $folder";
		return
	}
	my $base = $self->{BASE};
	my $parent = $self->{POOL};
	unless ($folder eq $base) {
		my $fpath;
		if ($base eq '/') {
			$fpath = substr($folder, 1);
		} else {
			$fpath = substr($folder, length($base) + 1);
		}
		my @path = split /\//, $fpath; # TODO separator for Win32
		for (@path) {
			my $c = $parent->{'children'};
			if (exists $c->{$_}) {
				$parent = $c->{$_}
			} else {
				die "$_ is not present in the data pool";
			}
		}
	}
	while (readdir($dh)) {
		my $item = $_;
		next if $item eq '.';
		next if $item eq '..';
		next if (($item =~ /^\..+/) and (not $self->cget('-showhidden')));
		my $fullname;
		if ($folder eq '/') {
			$fullname = "/$item"; # TODO separator for Win32
		} else {
			$fullname = "$folder/$item"; # TODO separator for Win32
		}
		$parent->{'children'}->{$item} = $self->GetStat($fullname);
		if (-d $fullname) {
			$self->folderRead($fullname, 0) if $recurse;
		}
	}
	$parent->{'loaded'} = 1;
	closedir $dh;
	return $parent;
}


sub GetDirIcon {
	my ($self, $name) = @_;
	return $self->Callback('-diriconcall', $name);
}

sub GetFileIcon {
	my ($self, $name) = @_;
	return $self->Callback('-fileiconcall', $name);
}

sub GetFullName {
	my ($self, $name) = @_;
	my $base = $self->{BASE};
	return $base if $name eq '';
	my $sep =  $self->cget('-separator');
	return $sep . $name if $base eq $sep;
	return $self->{BASE} . $self->cget('-separator') . $name
}

sub GetParent {
	my ($self, $name) = @_;
	my $dir = dirname($name);
	if ($dir eq '.') {
		$dir = '' ;
	}
	return $dir
}

sub GetPeers {
	my ($self, $name) = @_;
	return $self->infoChildren('') if $name eq $self->{BASE};
	return $self->infoChildren($self->GetParent($name));
}

sub GetSize {
	my ($self, $data) = @_;
	my $size;
	if (exists $data->{'children'}) {
		my $c = $data->{'children'};
		$size = keys %$c;
	} else {
		$size = $data->{'size'};
	}
	return $size
}

sub GetSizeString {
	my ($self, $data) = @_;
	my $size = $self->GetSize($data);
	if (exists $data->{'children'}) {
		$size = "$size items" if $size ne 1;
		$size = "$size item" if $size eq 1;
	} else {
	}
	return $size
}

sub GetStat {
	my ($self, $item) = @_;
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($item);
	my %itemdata = (
		dev => $dev,
		ino => $ino,
		mode => $mode,
		nlink => $nlink,
		uid => $uid,
		gid => $gid,
		rdev => $rdev,
		size => $size,
		atime => $atime,
		mtime => $mtime,
		ctime => $ctime,
		blksize => $blksize,
		blocks => $blocks,
	);
	if (-d $item) {
		$itemdata{'loaded'} = 0;
		$itemdata{'children'} = {};
		$itemdata{'open'} = 0;
	}
	return \%itemdata;
}

sub IndicatorPressed {
	my ($self, $entry, $action) = @_;
	my $mode = $self->getmode($entry);
	if ($action eq '<Arm>') {
		if ($mode eq 'open') {
			my @children = $self->infoChildren($entry);
			for (@children) {
				my $child = $_;
				if ($self->IsDir($child)) {
					unless ($self->IsLoaded($child)) {
						my $fchild = $self->GetFullName($child);
						my $cdata = $self->folderRead($fchild, 0);
						my $c = $cdata->{'children'};
						for (sort keys %$c) {
							my $new = "$child/$_";
							$self->AddItem($child, $_, $c->{$_});
						}
						$self->close($child) unless $self->infoData($child)->{'open'};
						my $col = $self->ColNum('Size');
						if (defined $col) {
							my $data = $self->infoData($child);
							$self->itemConfigure($child, $col, -text => $self->GetSizeString($data));
						}
					}
				}
			}
			$self->infoData($entry)->{'open'} = 1;
		} else {
			$self->infoData($entry)->{'open'} = 0;
		}
	}
	$self->IndicatorCmd($entry, $action);
}

sub Invoke {
	my ($self, $entry) = @_;
	my $full = $self->GetFullName($entry);
	if ($self->IsDir($entry)) {
		$self->load($full)
	} else {
		print "invoking $full\n";
		$self->Callback('-invokefile', $full)
	}
}

sub IsDir {
	my ($self, $entry) = @_;
	my $full = $self->GetFullName($entry);
	return -d $full
}

sub IsFile {
	my ($self, $entry) = @_;
	my $full = $self->GetFullName($entry);
	return not -d $full
}

sub IsLoaded {
	my ($self, $entry, $flag) = @_;
	my $data = $self->infoData($entry);
	if (defined $flag) {
		$data->{'loaded'} = $flag
	}
	return $data->{'loaded'}
}

=item B<load>I<$folder>

loads $folder into memory and refreshes the display
if succesfull.

=cut

sub load {
	my ($self, $folder) = @_;
	$folder = getcwd unless defined $folder;
	unless (-e $folder) {
		warn "'$folder' does not exist";
		return
	}
	unless (-d $folder) {
		warn "'$folder' is not a directory";
		return
	}
	$self->{POOL} = $self->GetStat($folder);
	$self->{BASE} = $folder;
	if (defined $self->folderRead($folder)) {
		my $mnutxt = $self->{MENUTXT};
		$$mnutxt = $folder;
		my @menu = ();
		my $pfolder = $folder;
		while ($pfolder ne '/') {
			$pfolder = dirname($pfolder);
			my $item = $pfolder;
			push @menu, [command => $item,
				-command => sub {
					print "loading $item\n";
					$self->load($item);
				},
			];
		}
		my $mb = $self->Subwidget('UpMenu');
		$mb->configure(-menu => $mb->Menu(
			-menuitems => \@menu,
		));
		$self->refresh;
	}
}

sub NumberOfColumns {
	my $self = shift;
	my $names = $self->{COLNAMES};
	my @size = keys %$names;
	my $num = @size;
	return $num
}

sub OrderTest {
	my ($self, $item, $peer, $itemdata) = @_;
	my $key = $self->{SORTON};
	my $sort =  $self->{SORTORDER};
	if ($key eq 'Name') {
		my $name = basename($item);
		unless ($self->cget('-casedependantsort')) {
			$name = lc($name);
			$peer = lc($peer);
		}
		if ($sort eq 'ascending') { 
			return $name lt $peer
		} else {
			return $name gt $peer
		}
	} elsif ($key eq 'Size') {
		my $isize = $self->GetSize($itemdata);
		my $psize = $self->GetSize($self->infoData($peer));
		if ($sort eq 'ascending') { 
			return $isize <= $psize
		} else {
			return $isize >= $psize
		}
	} else {
		my $tag = $timedata{$key};
		my $pdat = $self->infoData($peer)->{$tag};
		my $idat = $itemdata->{$tag};
		if ($sort eq 'ascending') { 
			return $idat <= $pdat
		} else {
			return $idat >= $pdat
		}
	}
}

sub Position {
	my ($self, $item, $itemdata) = @_;
	my $name = basename($item);
	my @peers = $self->GetPeers($item);
	return () unless @peers;
	my $directoriesfirst = $self->cget('-directoriesfirst');
	my @op = ();
	if ($self->IsDir($item) and $self->cget('-directoriesfirst')) {
		for (@peers) {
			my $peer = $_;
			if ($self->IsFile($peer)) { #we arrived at the end of the directory section
				push @op, -before => $peer;
				last;
			} elsif ($self->OrderTest($item, $peer, $itemdata)) {
				push @op, -before => $peer;
				last;
			}
		}
	} else {
		for (@peers) {
			my $peer = $_;
			if ($self->IsDir($peer)) { 
				#we are still in directory section, ignoring
			} elsif ($self->OrderTest($item, $peer, $itemdata)) {
				push @op, -before => $peer;
				last;
			}
		}
	}
	return @op;
}

sub PostConfig {
	my $self = shift;
	my $col = $self->cget('-columns');
	$self->CreateTreeWidget(@$col)
}

=item B<refresh>

Deletes all entries in the list and rebuilds it.

=cut

sub refresh {
	my $self = shift;
	$self->deleteAll;
	$self->update;
	my $pardir = '';
	my $root = $self->{POOL}->{'children'};
	for (sort keys %$root) {
		$self->AddItem('', $_, $root->{$_});
		$self->update;
	}
}

sub SortMode {
	my ($self, $column, $order) = @_;
	$self->{SORTON} = $column;
	$self->{SORTORDER} = $order;
	my $col = $self->NumberOfColumns - 1;
	for (0 .. $col) {
		my $num = $_;
		my $name = $self->ColName($_);
		my $widget = $self->headerCget($num, '-widget');
		if ($name eq $column) {
			$widget->configure('-sortorder', $order);
		} else {
			$widget->configure('-sortorder', 'none');
		}
	}
	my $base = $self->{BASE};
	$self->refresh;
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS AND CAVEATS

Everything is as yet untested at Windows.
Loading a large folder takes ages.

If you find any bugs, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::ITree>

=item L<Tk::Tree>

=back

=cut

1;



















