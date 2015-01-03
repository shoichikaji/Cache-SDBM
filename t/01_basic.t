use strict;
use warnings;
use utf8;
use Test::More;
use Cache::SDBM;
use File::Temp ();
sub tempdir { File::Temp::tempdir( CLEANUP => 1 ) }

subtest basic => sub {
    my $tempdir = tempdir;
    my $cache = Cache::SDBM->new("$tempdir/test");

    $cache->set("foo", "bar");
    is $cache->get("foo"), "bar";
    $cache->set("foo", "baz");
    is $cache->get("foo"), "baz";
    is $cache->get("not"), undef;


    $cache->remove("foo");
    is $cache->get("foo"), undef;
};

subtest error => sub {
    my $tempdir = tempdir;
    my $cache = Cache::SDBM->new("$tempdir/test");

    eval { $cache->set("foo", ["ref"]) };
    ok $@;
    diag $@;
    eval { $cache->set("foo", "x" x 2000) };
    ok $@;
    diag $@;
    eval { $cache->set("foo", "bar", { expire => 1 }) };
    ok $@;
    diag $@;
};

subtest expire => sub {
    my $tempdir = tempdir;
    my $cache = Cache::SDBM->new("$tempdir/test");

    $cache->set("foo", "bar", { expires_at => time - 1 });
    is $cache->get("foo"), undef;
    $cache->set("foo", "bar", { expires_in => 1 });
    is $cache->get("foo"), "bar";
    sleep 2;
    is $cache->get("foo"), undef;
};

subtest compute => sub {
    my $tempdir = tempdir;
    my $cache = Cache::SDBM->new("$tempdir/test");

    is $cache->compute("foo", sub { "bar" }), "bar";
    is $cache->get("foo"), "bar";
    my $called = 0;
    is $cache->compute("foo", sub { $called++; "new" }), "bar";
    is $called, 0;
};

subtest compute_expire => sub {
    my $tempdir = tempdir;
    my $cache = Cache::SDBM->new("$tempdir/test");

    $cache->compute("foo", { expires_at => time - 1 }, sub { "bar" });
    is $cache->get("foo"), undef;
    $cache->compute("foo", { expires_in => 1 }, sub { "bar" });
    is $cache->get("foo"), "bar";
    sleep 2;
    is $cache->get("foo"), undef;
};

subtest utf8 => sub {
    my $tempdir = tempdir;
    my $cache = Cache::SDBM->new("$tempdir/test");
    $cache->utf8(1);

    $cache->set("foo", "あ");
    is $cache->get("foo"), "あ";
    $cache->set("あ", "bar");
    is $cache->get("あ"), "bar";
};


done_testing;
