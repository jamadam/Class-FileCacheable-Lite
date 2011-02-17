package Class::FileCacheable::Lite;
use strict;
use warnings;
use Attribute::Handlers;
use Digest::MD5 qw(md5_hex);
use 5.005;
use File::Spec;
use File::Path;
use Fcntl qw(:flock);
our $VERSION = '0.02';
    
    my %fnames;
    
    ### ---
    ### return true if cache *EXPIRED*
    ### ---
    sub file_cache_expire {
        return 0;
    }
    
    ### ---
    ### return options
    ### ---
    sub file_cache_options {
        return {
            cache_root => File::Spec->catdir(File::Spec->tmpdir(), 'FileCache'),
            cache_depth     => 3,
            directory_umask => '000',
            number_cache_id => 0,
            namespace       => 'Default',
        };
    }
    
    ### ---
    ### Define FileCacheable attribute
    ### ---
    sub FileCacheable : ATTR(CHECK) {
        
        my($pkg, $sym, $ref, undef, $data, undef) = @_;
        
        no warnings 'redefine';
        
        *{$sym} = sub {
            my $self = shift;
            my %opt = (
                %{__PACKAGE__->file_cache_options},
                %{$self->file_cache_options}
            );
            my $cache_id_seed = $data->[0]->{key} || $opt{default_key};
            my $cache_id = *{$sym}. "\t". ($cache_id_seed || '');
            if ($opt{number_cache_id}) {
                $cache_id .= "\t" . ($fnames{*{$sym}}++);
            }
            
            my $output;
            
            my @idarray = split(//, md5_hex($cache_id), $opt{cache_depth} + 1);
            
            ### check if cache has expired
            my $fpath = File::Spec->catfile(
                $opt{cache_root},
                $opt{namespace},
                @idarray,
            );
            
            if (-f $fpath) {
                if (my $cache_tp = (stat $fpath)[9]) {
                    if ($data->[0]->{expire}) {
                        if (! $data->[0]->{expire}->($cache_tp)) {
                            $output = _get_cache($fpath);
                        }
                    } elsif (! $self->file_cache_expire($cache_tp)) {
                        $output = _get_cache($fpath);
                    }
                }
            }
            
            ### generate cache
            if (! defined($output)) {
                no strict 'refs';
                $output = $self->$ref(@_);
                umask $opt{directory_umask};
                
                pop(@idarray);
                mkpath(File::Spec->catfile($opt{cache_root}, $opt{namespace}, @idarray));
                
                if (open(my $OUT, '>:utf8', $fpath)) {
                    binmode($OUT, "utf8");
                    print $OUT $output;
                    close($OUT);
                } else {
                    print STDERR "Cache \"$fpath\" write failed";
                }
            }
            
            return $output;
        }
    }
    
    ### ---
    ### Get Cache
    ### ---
    sub _get_cache {
        
        my ($fpath) = @_;
        
        my $FH;
        if (open($FH, "<:utf8", $fpath) and flock($FH, LOCK_EX)) {
            my $a = do { local $/; <$FH> };
            close($FH);
            return $a;
        }
        die "Cache open failed";
    }

1;

__END__

=head1 NAME

Class::FileCacheable::Lite - Make you methods cacheable easily

=head1 SYNOPSIS

    use base 'Class::FileCacheable::Lite';
    
    sub file_cache_expire {
        my ($self, $timestamp) = @_;
        if (some_condifion) {
            return 1;
        }
    }
    
    sub file_cache_options {
        return {
            'namespace' => 'MyNamespace',
            'cache_root' => 't/cache',
            #...
        };
    }
    
    sub some_sub1 : FileCacheable {
        
        my $self = shift;
    }
    
    sub some_sub2 : FileCacheable({key => $key, expire => \&expire_code_ref}) {
        
        my $self = shift;
    }

=head1 DESCRIPTION

This module defines an attribute "FileCacheable" which redefines your functions
cacheable. 

To use this, do following steps.

=over

=item use base 'Class::FileCacheable';

=item override the method I<file_cache_expire>

=item override the method I<file_cache_option>

=item define your subs as follows

    sub your_sub : FileCacheable {
        my $self = shift;
        # do something
    }

=back

That's it.

=head1 METHODS

=head2 file_cache_expire

This is a callback method for specifying the condition for cache expiretion.
Your module can override the method if necessary.

file_cache_exipre will be called as instance method when the target method
called. This method takes timestamp of the cache as argument.

    sub file_cache_expire {
        my ($self, $timestamp) = @_;
        if (some_condifion) {
            return 1;
        }
    }

file_cache_exipre should return 1 or 0. 1 causes the cache *EXPIRED*

=head2 file_cache_options

This is a callback method for specifying options. Your module can override
the method if necessary.

    sub file_cache_options {
        return {
            'namespace' => 'Test',
            'cache_root' => 't/cache',
        };
    }

you can set options bellow

=over

=item cache_root

The location in the filesystem that will hold the root of the cache. Defaults
to the 'FileCache' under the OS default temp directory ( often '/tmp' on
UNIXes ) unless explicitly set.

=item cache_depth

The number of subdirectories deep to cache object item. This should be large
enough that no cache directory has more than a few hundred objects. Defaults
to 3 unless explicitly set.

=item directory_umask

The directories in the cache on the filesystem should be globally writable to
allow for multiple users. While this is a potential security concern, the
actual cache entries are written with the user's umask, thus reducing the risk
of cache poisoning. If you desire it to only be user writable, set
the 'directory_umask' option to '077' or similar. Defaults to '000' unless
explicitly set.

=item namespace

The namespace associated with this cache. Defaults to "Default" if not explicitly set.

=item number_cache_id

This takes 1 or 0 for value. '1' causes the cache ids automatically numbered so
the caches doesn't affect in single process. This is useful if you want to
cache the function calls as a sequence.

=back

=head2 file_cache_purge

Not implemented yet

=head1 EXAMPLE

    package GetExampleDotCom;
    use strict;
    use warnings;
    use base 'Class::FileCacheable::Lite';
    use LWP::Simple;
        
        sub new {
            my ($class, $url) = @_;
            return bless {url => $url}, $class;
        }
        
        sub get_url : FileCacheable {
            my $self = shift;
            return LWP::Simple::get($self->{url});
        }
    
        sub file_cache_expire {
            my ($self, $timestamp) = @_;
            if (time() - $timestamp > 86400) {
                return 1;
            }
        }
        
        sub file_cache_options {
            my $self = shift;
            return {
                namespace => 'Test',
                cache_root => 't/cache',
                default_key => $self->{url},
            };
        }

=head1 SEE ALSO

L<Class::FileCacheable>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
