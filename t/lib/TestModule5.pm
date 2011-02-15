package TestModule5;
use strict;
use warnings;
use base 'Class::FileCacheable::Lite';

    sub new {
        return bless {}, shift;
    }
    
	my $file_cache_expire_called;
	
    sub file_cache_expire {
		$file_cache_expire_called ||= 1;
        return 0;
    }
    
	my $file_cache_options_called;
	
    sub file_cache_options {
		$file_cache_options_called ||= 1;
        return {
            'namespace' => 'Test',
            'cache_root' => 't/cache',
        };
    }
	sub file_cache_expire_called {
		return $file_cache_expire_called;
	}
	sub get_file_cache_options_called {
		return $file_cache_options_called;
	}
	
package TestModule5sub;
use strict;
use warnings;
use base 'TestModule5';
    
    sub sub1 : FileCacheable {
        my $class = shift;
        return shift;
    }

1;
