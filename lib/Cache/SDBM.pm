package Cache::SDBM;
use 5.008001;
use strict;
use warnings;
use Carp 'croak';
use SDBM_File;
use Fcntl qw(:DEFAULT);
use Encode qw(encode_utf8 decode_utf8);

our $VERSION = "0.01";

sub new {
    my ($class, $filename) = @_;
    tie my %sdbm, 'SDBM_File', $filename, O_RDWR | O_CREAT, 0666
        or croak "open SDBM_File '$filename': $!";
    bless { sdbm => \%sdbm }, $class;
}

sub utf8 {
    my $self = shift;
    $self->{utf8} = shift if @_;
    $self->{utf8};
}

sub get {
    my ($self, $key) = @_;
    my $raw_value = $self->{sdbm}{ $self->utf8 ? encode_utf8($key) : $key };
    return unless defined $raw_value;

    $raw_value = decode_utf8 $raw_value if $self->utf8;

    my ($expires_at, $value) = split /\t/, $raw_value, 2;
    if (!$expires_at || $expires_at >= time) {
        return $value;
    } else {
        $self->remove($key);
        return;
    }
}

sub set {
    my ($self, $key, $value, $option) = @_;
    croak "value must not be a reference value" if ref $value;
    my $expires_at = "";
    if ($option) {
        if ($option->{expires_at}) {
            $expires_at = $option->{expires_at};
        } elsif ($option->{expires_in}) {
            $expires_at = time + $option->{expires_in};
        } else {
            my @key = keys %$option;
            croak "unexpected option: '@key'";
        }
    }

    my $raw_value = "$expires_at\t$value";

    if ($self->utf8) {
        $raw_value = encode_utf8 $raw_value;
        $key = encode_utf8 $key;
    }

    if ( 16 + length($key) + length($raw_value) > 1024 ) {
        croak "too long cache entry for key '$key'";
    }
    $self->{sdbm}{$key} = $raw_value;
}

sub remove {
    my ($self, $key) = @_;
    delete $self->{sdbm}{ $self->utf8 ? encode_utf8($key) : $key };
}

sub compute {
    my $self = shift;
    my $key  = shift;
    my $code = pop;
    my $option = shift;
    if (my $value = $self->get($key)) {
        return $value;
    } else {
        $self->set($key, $code->(), $option);
        $self->get($key);
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Cache::SDBM - simple cache based on SDBM_File

=head1 SYNOPSIS

    use Cache::SDBM;

    my $cache = Cache::SDBM->new("/path/to/cache.sdbm");

    # basic
    $cache->set(foo => "bar");
    my $value = $cache->get("foo");
    my $value = $cache->compute("baz", sub {
        # compute and return value for "baz"
    });

    # with expires_at or expires_in
    $cache->set(foo => "bar", { expires_at => time + 60*60 });
    my $value = $cache->get("foo");
    my $value = $cache->compute("baz", { expires_in => 24*60*60 }, sub {
        # compute and return value for "baz"
    });

=head1 DESCRIPTION

Cache::SDBM is a simple cache based on SDBM_File.

=head2 CONSTRUCTOR

=over 4

=item C<< $cache = Cache::SDBM->new($filename) >>

=back

=head2 METHODS

=over 4

=item C<< $value = $cache->get($key) >>

=item C<< $cache->set($key, $value, [$option]) >>

=item C<< $value = $cache->compute($key, [$option,] $code) >>

=item C<< $cache->remove($key) >>

=item C<< $bool = $cache->utf8, $cache->utf8($bool) >>

=back

=head1 CAVEATS

=over 4

=item *

Because we use SDBM for cache store,
the sum of key and value for each entry must be <= 1024 bytes.

=item *

The value for each entry must be a normal scalar value, not a reference.

=back

=head1 LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Shoichi Kaji E<lt>skaji@cpan.orgE<gt>

=cut

