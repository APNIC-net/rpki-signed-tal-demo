package APNIC::RPKI::TAK;

use warnings;
use strict;

use Convert::ASN1;
use DateTime;

use constant ID_SMIME  => '1.2.840.113549.1.9.16';
use constant ID_CT     => ID_SMIME . '.1';
use constant ID_CT_TAL => ID_CT . '.37';

use constant TAK_ASN1 => q<
    AlgorithmIdentifier ::= SEQUENCE {
        algorithm               OBJECT IDENTIFIER,
        parameters              ANY OPTIONAL
    }
    SubjectPublicKeyInfo ::= SEQUENCE {
        algorithm            AlgorithmIdentifier,
        subjectPublicKey     BIT STRING
    }
    CertificateURI ::= IA5String
    CurrentKey ::= SEQUENCE {
        certificateURIs       SEQUENCE OF CertificateURI,
        subjectPublicKeyInfo  SubjectPublicKeyInfo
    }
    TAK ::= SEQUENCE {
        version   [0] INTEGER,
        current   SEQUENCE OF CurrentKey,
        revoked   SEQUENCE OF SubjectPublicKeyInfo
    }
>;

use base qw(Class::Accessor);
APNIC::RPKI::TAK->mk_accessors(qw(
    version
    current_keys
    revoked_keys
));

sub new
{
    my ($class) = @_;

    my $parser = Convert::ASN1->new();
    $parser->configure(
        encoding => "DER",
        encode   => { time => "utctime" },
        decode   => { time => "utctime" }
    );
    my $res = $parser->prepare(TAK_ASN1());
    if (not $res) {
        die $parser->error();
    }
    $parser = $parser->find('TAK');

    my $self = { parser => $parser };
    bless $self, $class;
    return $self;
}

sub decode
{
    my ($self, $tak) = @_;

    my $parser = $self->{'parser'};
    my $data = $parser->decode($tak);
    if (not $data) {
        die $parser->error();
    }

    $self->version($data->{'version'});
    my @current = @{$data->{'current'}};
    my @current_keys =
        map { my $uris = $_->{'certificateURIs'};
              my $kd  = $_->{'subjectPublicKeyInfo'};
              my $key = {
                  'algorithm' => $kd->{'algorithm'}->{'algorithm'},
                  'content'   => $kd->{'subjectPublicKey'}->[0]
              };
              +{ urls => $uris,
                 public_key => $key } }
            @current;
    my @revoked = @{$data->{'revoked'}};
    my @revoked_keys =
        map { +{ algorithm => $_->{'algorithm'}->{'algorithm'},
                 content   => $_->{'subjectPublicKey'}->[0] } }
            @revoked;

    $self->current_keys(\@current_keys);
    $self->revoked_keys(\@revoked_keys);

    return 1;
}

1;
