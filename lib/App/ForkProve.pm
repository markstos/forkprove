package App::ForkProve;

use strict;
use 5.008_001;
our $VERSION = '0.3.0';

use App::Prove;
use Getopt::Long ':config' => 'pass_through';

use App::ForkProve::SourceHandler;

our @Blacklists = qw( Test::SharedFork );

sub process_preloads {
    my($class, @args) = @_;

    # Probably have to copy to @ARGV so that App::Prove can mangle it
    # in theory we don't need to, but doing so will make some tests fail
    # even with local @ARGV = () in SourceHandler. Not sure why...
    local @ARGV = @args;

    @ARGV = map { /^(-M)(.+)/ ? ($1,$2) : $_ } @ARGV;

    my @modules;
    my $lib;
    my $blib;
    my @inc;
    Getopt::Long::GetOptions('M=s@', \@modules);
    Getopt::Long::GetOptionsFromArray([@ARGV],
        'l|lib',  \$lib,
        'b|blib', \$blib,
        'I=s@',   \@inc,
    );

    if ($lib) {
        unshift @inc, 'lib';
    }

    if ($blib) {
        unshift @inc, 'blib/lib', 'blib/arch';
    }


    for (@modules) {
        my($module, @import) = split /[=,]/;
        local @INC{map pkg_to_file($_), @Blacklists} = (__FILE__) x scalar(@Blacklists);
        local @INC = (@inc, @INC);

        eval "require $module" or die $@;
        $module->import(@import);
    }
}

sub run {
    my $app = App::Prove->new;
    $app->process_args(@ARGV);
    $app->run;
}

sub pkg_to_file {
    local $_ = shift;
    s|::|/|g;
    "$_.pm";
}


1;
__END__

=encoding utf-8

=head1 NAME

App::ForkProve - forking prove

=head1 SYNOPSIS

  use App::ForkProve;
  App::ForkProve->run(@ARGV);

=head1 DESCRIPTION

App::ForkProve is a backend for L<forkprove>.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2012- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<forkprove>

=cut
