package TestModule4;
use strict;
use warnings;
use base 'Class::FileCacheable::Lite';

    sub new {
        return bless {}, shift;
    }
    
    sub sub1 : FileCacheable {
        my $class = shift;
        return shift;
    }
    
    my $debug_timestamp;
    
    sub file_cache_expire {
        my ($self, $timestamp) = @_;
        $debug_timestamp ||= $timestamp;
        return 0;
    }
    
    sub get_debug_timestamp {
        return $debug_timestamp;
    }
    
    sub file_cache_options {
        return {
            'namespace' => 'Test',
            'cache_root' => 't/cache',
        };
    }
    
    sub sub2 : FileCacheable({expire => \&sub2_cache_expire}) {
        my $class = shift;
        return shift;
    }
    
    sub sub2_cache_expire {
        my ($self, $timestamp) = @_;
        return 1;
    }

1;
