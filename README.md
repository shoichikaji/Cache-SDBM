# NAME

Cache::SDBM - simple cache based on SDBM\_File

# SYNOPSIS

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

# DESCRIPTION

Cache::SDBM is a simple cache based on SDBM\_File.

## CONSTRUCTOR

- `$cache = Cache::SDBM->new($filename)`

## METHODS

- `$value = $cache->get($key)`
- `$cache->set($key, $value, [$option])`
- `$value = $cache->compute($key, [$option,] $code)`
- `$cache->remove($key)`
- `$bool = $cache->utf8, $cache->utf8($bool)`

# CAVEATS

- Because we use SDBM for cache store,
the sum of key and value for each entry must be <= 1024 bytes.
- The value for each entry must be a normal scalar value, not a reference.

# LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Shoichi Kaji <skaji@cpan.org>
