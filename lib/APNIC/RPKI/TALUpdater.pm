package APNIC::RPKI::TALUpdater;

use warnings;
use strict;

use Cwd qw(getcwd);
use Data::Dumper;
use Digest::SHA qw(sha256 sha256_hex);
use File::Slurp qw(read_file write_file);
use File::Temp qw(tempdir);
use JSON::XS qw(encode_json decode_json);
use List::Util qw(first);
use List::MoreUtils qw(uniq);
use MIME::Base64 qw(encode_base64);
use URI;

use APNIC::RPKI::OpenSSL;
use APNIC::RPKI::Manifest;
use APNIC::RPKI::TAK;
use APNIC::RPKI::Utilities qw(canonicalise_pem);

use constant THIRTY_DAYS => 60 * 60 * 24 * 30;

our $VERSION = '0.1';

sub new
{
    my $class = shift;

    my %args = @_;
    my $self = { %args, openssl => APNIC::RPKI::OpenSSL->new() };
    bless $self, $class;

    return $self;
}

sub _fetch_rsync_path
{
    my ($self, $path) = @_;

    if ($path !~ /^rsync:\/\//) {
        die "Path ($path) is not an rsync path.";
    }

    chdir $self->{'output'} or die $!;
    my ($domain, $name) = ($path =~ /^rsync:\/\/(.*?)\/(.*)/);
    if (not -e $domain) {
        mkdir $domain or die $!;
    }
    chdir $domain or die $!;
    if ($name =~ /\.[^\.]{3}$/) {
        my ($dir, $base) = ($name =~ /^(.*)\/(.*)$/);
        if (not $dir) {
            my $res = system("rsync -Laz --delete $path $name");
            if ($res != 0) {
                die "Unable to fetch file ($path)";
            }
        } else {
            my $res = system("mkdir -p $dir");
            if ($res != 0) {
                die "Unable to make repository directory ($dir)";
            }
            chdir $dir or die $!;
            $res = system("rsync -Laz --delete $path .");
            if ($res != 0) {
                die "Unable to fetch file ($path)";
            }
        }
    } else {
        my ($dir, $base) = ($name =~ /^(.*)\/(.*)$/);
        if (not $dir) {
            my $res = system("rsync -Laz --delete $path $name");
            if ($res != 0) {
                die "Unable to fetch file ($path)";
            }
        } else {
            my $res = system("mkdir -p $dir");
            if ($res != 0) {
                die "Unable to make repository directory ($dir)";
            }
            chdir $dir or die $!;
            $res = system("rsync -Laz --delete $path .");
            if ($res != 0) {
                die "Unable to fetch file ($path)";
            }
        }
    }
    return 1;
}

sub _parse_tal
{
    my ($lines) = @_;

    my @urls;
    my @key_data;
    while (my $line = shift(@{$lines})) {
        chomp $line;
        if ($line eq '') {
            last;
        }
        if ($line =~ /^#/) {
            next;
        }
        if ($line !~ /^rsync:/) {
            push @key_data, $line;
            last;
        }
        push @urls, $line;
    }
    while (my $line = shift(@{$lines})) {
        chomp $line;
        push @key_data, $line;
    }

    return { urls => \@urls,
             public_key => {
                algorithm => "1.2.840.113549.1.1.11",
                content => (join '', @key_data)
             } };
}

sub _get_path
{
    my ($self, $url) = @_;

    chdir $self->{'output'} or die $!;
    my $path = $url;
    $path =~ s/^rsync:\/\///;

    my $matching_fetch =
        first { my $fetch = $self->{'fetched'}->{$_};
                $url =~ /^$fetch/ }
            keys %{$self->{'fetched'}};

    if (not $matching_fetch) {
        $self->_fetch_rsync_path($url);
        $self->{'fetched'}->{$url} = 1;
    }
    return $self->{'output'}."/$path";
}

sub _process_tal
{
    my ($self, $tal_data, $no_recurse) = @_;

    my $cert_rsync_url =
        first { $_ =~ /^rsync/ }
            @{$tal_data->{'urls'}};

    my $openssl = $self->{'openssl'};

    my $cert_path = $self->_get_path($cert_rsync_url);
    my $cert_pem_data = $openssl->to_pem($cert_path);
    my $cert_pem_ft = File::Temp->new();
    print $cert_pem_ft $cert_pem_data;
    $cert_pem_ft->flush();
    my $cert_pem_path = $cert_pem_ft->filename();

    my $repo_url = $openssl->get_repository_url($cert_path);
    $self->_get_path($repo_url);
    my $mft_url = $openssl->get_manifest_url($cert_path);
    my $mft_path = $self->_get_path($mft_url);
    my $mft_data = $openssl->verify_cms($mft_path, $cert_pem_path);

    my $mft = APNIC::RPKI::Manifest->new();
    eval { $mft->decode($mft_data); };
    if (my $error = $@) {
        die "Unable to decode manifest ($mft_path): $error";
    }

    for my $file (@{$mft->files()}) {
        my $path = $self->_get_path($repo_url.'/'.$file->{'filename'});
        my $expected_hash = $file->{'hash'};
        my $data = read_file($path);
        my $hash = sha256($data);
        if ($hash ne $expected_hash) {
            die "incorrect manifest file hash for ".
                $file->{'filename'};
        }
    }

    my @crls = grep { $_->{'filename'} =~ /\.crl$/ } @{$mft->files()};
    if (@crls != 1) {
        die "no CRL found";
    }
    my $crl = $crls[0];

    my $crl_filename = $crl->{'filename'};
    my $crl_url = $repo_url.'/'.$crl_filename;
    my $crl_path = $self->_get_path($crl_url);
    my %crl_serials = map { $_ => 1 } $openssl->get_crl_serials($crl_path);

    my $mft_ee_cert = $openssl->get_ee_cert($mft_path);
    my $mft_serial = $openssl->get_serial($mft_ee_cert);
    if ($crl_serials{$mft_serial}) {
        die "manifest EE certificate is revoked";
    }

    my @taks = grep { $_->{'filename'} =~ /\.tak$/ } @{$mft->files()};
    if (@taks > 1) {
        die "multiple TAKs found (there can only be zero or one)";
    }

    my $tak = $taks[0];
    if (not $tak) {
        warn "no TAK found";
        return;
    }

    my $tak_filename = $tak->{'filename'};
    my $tak_url = $repo_url.'/'.$tak_filename;
    my $tak_path = $self->_get_path($tak_url);

    my $tak_obj = APNIC::RPKI::TAK->new();
    my $tak_data = $openssl->verify_cms($tak_path, $cert_pem_path);
    my $tak_ee_cert = $openssl->get_ee_cert($tak_path);
    my $serial = $openssl->get_serial($tak_ee_cert);
    if ($crl_serials{$serial}) {
        die "TAK EE certificate is revoked";
    }
    if (not $openssl->is_inherit($tak_ee_cert)) {
        die "TAK EE certificate does not use the inherit bit";
    }

    write_file("/tmp/tak", $tak_data);
    write_file("/tmp/takpath", $tak_path);

    eval { $tak_obj->decode($tak_data); };
    if (my $error = $@) {
        die "Unable to decode TAK object: $error";
    }
    if ($tak_obj->version() != 0) {
        die "TAK version must be 0";
    }

    # Check that the current key matches the key used to issue the
    # TAK.

    my $current = $tak_obj->current();
    if (not $current) {
        die "TAK does not contain a current key";
    }
    my $ta_key_from_cert = $openssl->get_public_key($cert_pem_data);
    shift @{$ta_key_from_cert};
    pop @{$ta_key_from_cert};
    my $content = join '', @{$ta_key_from_cert};
    my $parser = Convert::ASN1->new();
    $parser->configure(
        tagdefault => 'EXPLICIT',
        encoding   => "DER",
        encode     => { time => "utctime" },
        decode     => { time => "utctime" }
    );
    $parser = $parser->prepare(APNIC::RPKI::TAK::TAK_ASN1())->find('SubjectPublicKeyInfo');
    my $ta_key_from_tak =
        encode_base64($parser->encode($current->{'public_key'}));
    $ta_key_from_tak =~ s/\n//g;
    if ($content ne $ta_key_from_tak) {
        die "TAK key does not match TA key: ".
            $content.", ".$ta_key_from_tak;
    }

    # If no_recurse is true, then this is validating a successor key,
    # and there is no need to validate further successor keys.

    if ($no_recurse) {
        return ($tak_obj);
    }

    # If there is a successor key, then make TAL data from it, and
    # process that TA as well.  Otherwise, just return the TAK data
    # from this TA.

    my $successor = $tak_obj->successor();
    if (not $successor) {
        return ($tak_obj);
    } else {
        my $key_data_out =
            canonicalise_pem(
                encode_base64(
                    $parser->encode($successor->{'public_key'})
                )
            );
        my @tal_lines = (
            @{$successor->{'uris'}},
            "",
            (split /\n/, $key_data_out)
        );
        my $tal_data = _parse_tal(\@tal_lines);
        my ($extra_tak_obj) = $self->_process_tal($tal_data);
        return ($tak_obj, $extra_tak_obj);
    } 

    return 1;
}

sub run
{
    my ($self) = @_;

    my $cwd = getcwd();

    my $tal_path = $self->{'tal_path'};
    $self->{'output'} = tempdir();

    my $state_path = $self->{'state_path'};
    my $state_data = read_file($state_path) || '{}';
    my $state = decode_json($state_data);

    my @lines = read_file($tal_path);
    my $tal_data = _parse_tal(\@lines);
    my ($current_tak_obj, $successor_tak_obj) =
        $self->_process_tal($tal_data);

    my $use_successor = 0;

    my $state_key =
        sha256_hex($tal_data->{'public_key'}->{'content'});

    my $parser = Convert::ASN1->new();
    $parser->configure(
        tagdefault => 'EXPLICIT',
        encoding   => "DER",
        encode     => { time => "utctime" },
        decode     => { time => "utctime" }
    );
    $parser = $parser->prepare(APNIC::RPKI::TAK::TAK_ASN1())->find('SubjectPublicKeyInfo');

    if (not $successor_tak_obj) {
        print "debug: no successor for this TAL\n";
        # If there is a timer for this TAL, clear it.
        if ($state->{$state_key}->{'timer'}) {
            print "debug: deleting existing timer for $tal_path\n";
            delete $state->{$state_key}->{'timer'};
        }
    } else {
        my $success = 1;
        # There is a successor TAK object.  Confirm that the original
        # key and the successor key match.
        my $current_successor =
            $parser->encode($current_tak_obj->successor()->{'public_key'});
        my $successor_current =
            $parser->encode($successor_tak_obj->current()->{'public_key'});
        my $current_current =
            $parser->encode($current_tak_obj->current()->{'public_key'});
        my $successor_predecessor =
            $parser->encode($successor_tak_obj->predecessor()->{'public_key'});

        if ($current_successor ne $successor_current) {
            print "debug: successor in current key does not match ".
                  "current in successor key\n";
            print "debug: successor in current key: ".
                  encode_base64($current_successor)."\n";
            print "debug: current in successor key: ".
                  encode_base64($successor_current)."\n";
            $success = 0;
        }
        if ($current_current ne $successor_predecessor) {
            print "debug: current in current key does not match ".
                  "predecessor in successor key\n";
            print "debug: current in current key: ".
                  encode_base64($current_current)."\n";
            print "debug: predecessor in successor key: ".
                  encode_base64($successor_predecessor)."\n";
            $success = 0;
        }
        if (not $success) {
            if ($state->{$state_key}->{'timer'}) {
                print "debug: deleting existing timer for $tal_path ".
                      "(successor key links are invalid)\n";
                delete $state->{$state_key}->{'timer'};
            }
        } else {
            if (not $state->{$state_key}->{'timer'}) {
                print "debug: new successor key, adding acceptance timer for $tal_path\n";
                $state->{$state_key}->{'timer'} = {
                    first_seen => time(),
                    key_data => encode_base64($successor_current)
                };
            } else {
                # Confirm that the successor still matches.  If it
                # doesn't, set a new timer.  If it does, and the timer
                # has reached 30 days, switch to the new TAL.
                my $timer = $state->{$state_key}->{'timer'};
                if ($timer->{'key_data'} eq encode_base64($successor_current)) {
                    print "debug: successor still matches\n";
                    if ($timer->{'first_seen'} + THIRTY_DAYS < time()) {
                        print "debug: successor acceptance timer has expired\n";
                        $use_successor = 1;
                        delete $state->{$state_key}->{'timer'};
                    } else {
                        print "debug: successor acceptance timer has not expired\n";
                    }
                } else {
                    print "debug: successor does not match existing ".
                          "timer key, resetting timer\n";
                    $state->{$state_key}->{'timer'} = {
                        first_seen => time(),
                        key_data => encode_base64($successor_current)
                    };
                }
            }
        }
    }

    if ($use_successor) {
        print "debug: transitioning to successor key\n";
        my $key = $successor_tak_obj->current();
        my $key_data_out =
            canonicalise_pem(
                encode_base64(
                    $parser->encode($key->{'public_key'})
                )
            );
        if (not @{$key->{'uris'}}) {
            die "no URIs in successor key";
        }
        my @tal_lines =
            (join "\n", map { "# ".$_ } @{$key->{'comments'} || []})."\n".
            (join "\n", @{$key->{'uris'} || []})."\n\n".
            $key_data_out;
        chdir($cwd);

        write_file($tal_path, @tal_lines);
    } else {
        print "debug: not transitioning to successor key\n";
    }

    chdir($cwd);
    write_file($state_path, encode_json($state));

    return 1;
}

1;
