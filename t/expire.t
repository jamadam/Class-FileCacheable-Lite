package main;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use base 'Test::Class';
use TestModule7;
use File::Path;
    
    my $cache_namespace_base = 't/cache/Test';
    
    __PACKAGE__->runtests;
    
    sub dynamicaly_asign_id : Test(4) {
        
        if (-d $cache_namespace_base) {
            rmtree($cache_namespace_base);
        }
        {
            my $a = TestModule7->new();
            is($a->get_method1_count, 0);
            $a->method1;
            is($a->get_method1_count, 1);
            $a->method1;
            is($a->get_method1_count, 1);
			sleep(3);
            $a->method1;
            is($a->get_method1_count, 2);
        }
    }
    
    END {
        if (-d $cache_namespace_base) {
            rmtree($cache_namespace_base);
        }
    }

1;
