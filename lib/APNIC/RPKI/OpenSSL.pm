package APNIC::RPKI::OpenSSL;

use warnings;
use strict;

use File::Slurp qw(read_file);
use File::Temp;
use Net::CIDR::Set;
use Set::IntSpan;

use APNIC::RPKI::Utilities qw(system_ad);

our $VERSION = '0.1';

sub new
{
    my $class = shift;

    my %args = @_;
    my $self = \%args;

    if (not $self->{'path'}) {
        $self->{'path'} = "/usr/local/ssl/bin/openssl";
    }

    bless $self, $class;
    return $self;
}

sub get_openssl_path
{
    my ($self) = @_;

    return $self->{'path'};
}

sub to_pem
{
    my ($self, $input_path) = @_;

    my $ft_output = File::Temp->new();
    my $fn_output = $ft_output->filename();

    my $openssl = $self->get_openssl_path();
    system_ad("$openssl x509 -inform DER ".
              "-in $input_path ".
              "-outform PEM ".
              "-out $fn_output",
              $self->{'debug'});

    return read_file($fn_output);
}

sub verify_cms
{
    my ($self, $input, $ca_cert) = @_;

    my $ft_output = File::Temp->new();
    my $fn_output = $ft_output->filename();

    my $openssl = $self->get_openssl_path();
    system_ad("$openssl cms -verify -inform DER ".
              "-in $input ".
              "-CAfile $ca_cert ".
              "-out $fn_output",
              $self->{'debug'});

    return read_file($fn_output);
}

sub get_repository_url
{
    my ($self, $cert) = @_;

    my $ft_cert;
    my $fn_cert;
    if (-e $cert) {
        $fn_cert = $cert;
    } else {
        my $ft_cert = File::Temp->new();
        print $ft_cert $cert;
        $ft_cert->flush();
        $fn_cert = $ft_cert->filename();
    }

    my $openssl = $self->get_openssl_path();
    my $cmd_str = "$openssl x509 -inform DER -in $fn_cert ".
                  "-text -noout | grep 'CA Repository - URI:'";
    my ($repo_url) = `$cmd_str`;
    $repo_url =~ s/.*?URI://;
    $repo_url =~ s/\s*$//;

    return $repo_url;
}

sub get_manifest_url
{
    my ($self, $cert) = @_;

    my $ft_cert;
    my $fn_cert;
    if (-e $cert) {
        $fn_cert = $cert;
    } else {
        my $ft_cert = File::Temp->new();
        print $ft_cert $cert;
        $ft_cert->flush();
        $fn_cert = $ft_cert->filename();
    }

    my $openssl = $self->get_openssl_path();
    my $cmd_str = "$openssl x509 -inform DER -in $fn_cert ".
                  "-text -noout | grep 'URI.*\.mft'";
    my ($mft_url) = `$cmd_str`;
    $mft_url =~ s/.*?URI://;
    $mft_url =~ s/\s*$//;

    return $mft_url;
}

1;
