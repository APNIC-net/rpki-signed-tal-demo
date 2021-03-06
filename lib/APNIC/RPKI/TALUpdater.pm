package APNIC::RPKI::TALUpdater;

use warnings;
use strict;

use Cwd qw(getcwd);
use Digest::SHA qw(sha256);
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
        my $res = system("mkdir -p $dir");
        if ($res != 0) {
            die "Unable to make repository directory ($path)";
        }
        chdir $dir;
        $res = system("rsync -Laz --delete $path .");
        if ($res != 0) {
            die "Unable to fetch file ($path)";
        }
    } else {
        my ($dir, $base) = ($name =~ /^(.*)\/(.*)$/);
        if (not $dir) {
            my $res = system("rsync -Laz --delete $path $name");
            if ($res != 0) {
                die "Unable to fetch repository ($name)";
            }
        } else {
            my $res = system("mkdir -p $dir");
            if ($res != 0) {
                die "Unable to make repository directory ($dir)";
            }
            chdir $dir;
            $res = system("rsync -Laz --delete $path .");
            if ($res != 0) {
                die "Unable to fetch repository ($path)";
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
    my ($self, $tal_data) = @_;

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
    $mft->decode($mft_data);

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

    $tak_obj->decode($tak_data);
    if ($tak_obj->version() != 0) {
        die "TAK version must be 0";
    }

    my @tak_revoked_keys = @{$tak_obj->revoked_keys()};
    for my $k (@tak_revoked_keys) {
        $k->{'content'} = encode_base64($k->{'content'}, '');
    }
    for my $tak_revoked_key (@tak_revoked_keys) {
        my $exists =
            first { $_->{'content'} eq $tak_revoked_key->{'content'}
                and $_->{'algorithm'} eq $tak_revoked_key->{'algorithm'} }
                @{$self->{'state'}->{'revoked'}};
        if (not $exists) {
            push @{$self->{'state'}->{'revoked'}}, $tak_revoked_key;
        }
    }

    my @tak_current_keys = @{$tak_obj->current_keys()};
    for my $k (@tak_current_keys) {
        $k->{'public_key'}->{'content'} =
            encode_base64($k->{'public_key'}->{'content'}, '');
    }
    for my $tak_current_key (@tak_current_keys) {
        my @urls = @{$tak_current_key->{'urls'}};
        for my $url (@urls) {
            my $uri = URI->new($url);
            my $scheme = $uri->scheme();
            if ($scheme ne 'rsync' and $scheme ne 'https') {
                die "Certificate URL must be rsync or https";
            }
        }
        my $pk = $tak_current_key->{'public_key'};
        my $exists =
            first { my $spk = $_->{'public_key'};
                    $spk->{'content'} eq $pk->{'content'} }
                @{$self->{'state'}->{'current'}};
        if (not $exists) {
            push @{$self->{'state'}->{'current'}}, $tak_current_key;
        } else {
            my @urls = uniq @{$tak_current_key->{'urls'}};
            push @{$exists->{'new_urls'}}, @urls;
        }
    }

    return 1;
}

sub run
{
    my ($self) = @_;

    my $cwd = getcwd();

    my ($tal_path, $state_path) =
        @{$self}{qw(tal_path state_path)};
    $self->{'output'} = tempdir();

    if ((not -e $state_path) or ((stat($state_path))[7] == 0)) {
        my @lines = read_file($tal_path);
        my $tal_data = _parse_tal(\@lines);
        $self->{'state'}->{'current'} = [ $tal_data ];
    } else {
        my $state = read_file($state_path);
        $self->{'state'} = decode_json($state);
    }
    my $state = $self->{'state'};

    my %revoked =
        map { $_->{'algorithm'}.':'.
              $_->{'content'} => 1 }
            @{$state->{'revoked'}};

    for my $tal_data (@{$state->{'current'}}) {
        my $pk = $tal_data->{'public_key'};
        my $rkey = $pk->{'algorithm'}.':'.$pk->{'content'};
        if ($revoked{$rkey}) {
            next;
        }
        $self->_process_tal($tal_data);
    }
    for my $key (@{$state->{'current'}}) {
        $key->{'urls'} = [ uniq @{$key->{'new_urls'}} ];
        delete $key->{'new_urls'};
    }

    %revoked =
        map { $_->{'algorithm'}.':'.
              $_->{'content'} => 1 }
            @{$state->{'revoked'}};

    my $current =
        first { not $revoked{$_->{'public_key'}->{'algorithm'}.':'.
                             $_->{'public_key'}->{'content'}} }
            @{$state->{'current'}};
    if (not $current) {
        die "all keys revoked: leaving tal/state unchanged";
    }
    my $key_data_out =
        canonicalise_pem($current->{'public_key'}->{'content'});

    chdir($cwd);

    write_file($tal_path,
               (join "\n", @{$current->{'urls'}})."\n\n".
               $key_data_out);
    write_file($state_path, encode_json($state));

    return 1;
}

1;
