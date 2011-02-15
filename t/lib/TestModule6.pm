package TestModule6;
use strict;
use warnings;
use base 'Class::FileCacheable::Lite';
use LWP::Simple;
    
    my $lwp_count = 0;
    
    sub get_lwp_count {
        return $lwp_count;
    }
    
    sub new {
        my ($class, $url) = @_;
        return bless {url => $url}, $class;
    }
    
    sub get_url : FileCacheable {
        my $self = shift;
        $lwp_count++;
        return LWP::Simple::get($self->{url});
    }
    
    sub file_cache_options {
        my $self = shift;
        return {
            namespace => 'Test',
            cache_root => 't/cache',
            default_key => $self->{url},
        };
    }

1;
