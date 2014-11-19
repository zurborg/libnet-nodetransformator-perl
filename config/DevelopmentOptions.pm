addopt(
    postamble => {
        REDMINE_BASEURL     => '',
        REDMINE_PROJECT     => '',
        README_SECTIONS     => [ 'NAME', 'VERSION', 'DESCRIPTION', 'AUTHOR', 'SUPPORT', 'COPYRIGHT & LICENSE' ],
    },
    depend => {
        '$(FIRST_MAKEFILE)' => 'config/BuildOptions.pm config/DevelopmentOptions.pm',
    },
);

sub extend_makefile {
	
	my $out;
	
	while (@_) {
		my $target = shift;
		$out .= "$target :: ";
		my %opts = %{ shift() };
		if (exists $opts{preq}) {
			$out .= join ' ' => @{ $opts{preq} };
		}
		$out .= "\n";
		if (exists $opts{cmds}) {
			$out .= join "\n" => map { "\t$_" } @{ $opts{cmds} };
		}
		$out .= "\n\n";
	}
	
	return $out;
}

sub MY::postamble {
	my ($MM, %options) = @_;
	return main::extend_makefile(
		'documentation/README.pod' => {
			preq => [ $MM->{ABSTRACT_FROM} ],
			cmds => [
				'podselect '.join(' ' => map { "-section '$_'" } @{ $options{README_SECTIONS} }).' -- "$<" > "$@"'
			]
		},
		README => {
			preq => [qw[ documentation/README.pod ]],
			cmds => [
				'pod2readme "$<" "$@" README'
			]
		},
		'README.md' => {
			preq => [qw[ documentation/README.pod ]],
			cmds => [
				'pod2markdown "$<" "$@"'
			]
		},
		INSTALL => {
			preq => [qw[ documentation/INSTALL.pod ]],
			cmds => [
				'pod2readme "$<" "$@" README'
			]
		},
		documentation => {
			preq => [qw[ README README.md INSTALL ]],
		},
		'all' => {
			preq => [qw[ documentation MANIFEST.SKIP ]]
		},
		'MANIFEST.SKIP' => {
			preq => [qw[ MANIFEST.IGNORE ]],
			cmds => [
			    'echo "#!include_default" > "$@" ',
			    'for file in $?; do echo "#!include $$file" >> "$@"; done',
			    '$(MAKE) skipcheck',
			]
		},
	);
}