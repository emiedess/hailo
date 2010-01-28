use utf8;
use strict;
use warnings;
use Test::More tests => 42;
use Hailo;
use Data::Random qw(:all);
use File::Temp qw(tempfile tempdir);

binmode $_, ':encoding(utf8)' for (*STDIN, *STDOUT, *STDERR);

# Suppress PostgreSQL notices
$SIG{__WARN__} = sub { print STDERR @_ if $_[0] !~ m/NOTICE:\s*CREATE TABLE/; };

for my $backend (qw(Perl Pg SQLite)) {
    # Skip all tests for this backend?
    my $skip_all;

    # Dir to store our brains
    my $dir = tempdir( CLEANUP => 1 );
    ok($dir, "Got temporary dir $dir");

    my ($fh, $filename) = tempfile( DIR => $dir, SUFFIX => '.db' );
    ok($filename, "Got temporary file $filename");

    if ($backend eq "Pg") {
        # It doesn't use the file to store data obviously, it's just a convenient random token.
        if (system "createdb '$filename'") {
            $skip_all = 1;
            pass("Skipping PostgreSQL tests, can't create a database named '$filename'");
        } else {
            pass("Created PostgreSQL '$filename' database");
        }
    }

    my $prev_brain;
    for my $i (1 .. 5) {
      SKIP: {
        skip "Didn't create PostgreSQL db, can't test it", 2 if $skip_all;
        my $hailo = Hailo->new(
            storage_class  => $backend,
            brain_resource => $filename,
        );

        if ($backend eq "Perl") {
            if ($prev_brain) {
                my $this_brain = $hailo->_storage_obj->_memory;
                is_deeply($prev_brain, $this_brain, "$backend: Our previous $backend brain matches the new one, try $i");
            }
        }

        # Get some training material
        my $size = 10;
        my @random_words = rand_words( size => $size );
        is(scalar @random_words, $size, "$backend: Got $size words to train on, try $i");

        # Learn from it
        $hailo->learn("@random_words");

        # Hailo replies
        cmp_ok(length($hailo->reply($random_words[5])) * 2, '>', length($random_words[5]), "Hailo knows how to babble, try $i");

        if ($backend eq "Perl") {
            # Save this brain for the next iteration
            $prev_brain = $hailo->_storage_obj->_memory;
        }

        $hailo->save();
        undef $hailo;
      }
    }

    if ($backend eq "Pg") {
      SKIP: {
        skip "Didn't create PostgreSQL db, no need to drop it", 1 if $skip_all;
        system "dropdb '$filename'" and die "Couldn't drop temporary PostgreSQL database '$filename': $!";
        pass("Dropped PostgreSQL '$filename' database");
      }
    }

    # Don't skip for the next backend
    $skip_all = 0;
}
