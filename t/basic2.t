package main;
use strict;
use warnings;
use lib 't/lib', 'lib';
use Test::More;
use base 'Test::Class';
use TestModule6;
use File::Path;
    
    my $cache_namespace_base = 't/cache/Test';
    
    __PACKAGE__->runtests;
    
    sub dynamicaly_asign_id : Test(5) {
        
        if (-d $cache_namespace_base) {
            rmtree($cache_namespace_base);
        }
        {
            my $a = TestModule6->new('http://example.com/');
            is($a->get_lwp_count, 0);
            $a->get_url;
            is($a->get_lwp_count, 1);
            $a->get_url;
            is($a->get_lwp_count, 1);
        }
        {
            my $a = TestModule6->new('http://example.com/2');
            $a->get_url;
            is($a->get_lwp_count, 2);
            $a->get_url;
            is($a->get_lwp_count, 2);
        }
    }
    
    END {
        if (-d $cache_namespace_base) {
            rmtree($cache_namespace_base);
        }
    }
    