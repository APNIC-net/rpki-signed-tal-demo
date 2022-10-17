package APNIC::RPKI::TAK;

use warnings;
use strict;

use Convert::ASN1;
use DateTime;

use constant ID_SMIME  => '1.2.840.113549.1.9.16';
use constant ID_CT     => ID_SMIME . '.1';
use constant ID_CT_TAL => ID_CT . '.50';

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
    TAKey ::= SEQUENCE {
        comments              SEQUENCE OF UTF8String,
        certificateURIs       SEQUENCE OF CertificateURI,
        subjectPublicKeyInfo  SubjectPublicKeyInfo
    }
    TAK ::= SEQUENCE {
        version     INTEGER OPTIONAL,
        current     TAKey,
        predecessor [0] TAKey OPTIONAL,
        successor   [1] TAKey OPTIONAL
    }
>;

use base qw(Class::Accessor);
APNIC::RPKI::TAK->mk_accessors(qw(
    version
    current
    predecessor
    successor
));

sub new
{
    my ($class) = @_;

    my $parser = Convert::ASN1->new();
    $parser->configure(
        tagdefault => 'EXPLICIT',
        encoding   => "DER",
        encode     => { time => "utctime" },
        decode     => { time => "utctime" }
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

sub _decode_key
{
    my ($key) = @_;

    my $comments = $key->{'comments'};
    my $uris = $key->{'certificateURIs'};
    my $key_data = $key->{'subjectPublicKeyInfo'};
    my %key_decoded = (
        'comments'   => $comments,
        'uris'       => $uris,
        'public_key' => $key_data,
    );
    return \%key_decoded;
}

sub decode
{
    my ($self, $tak) = @_;

    my $parser = $self->{'parser'};
    my $data = $parser->decode($tak);
    if (not $data) {
        die $parser->error();
    }

    $self->version($data->{'version'} || 0);
    my $current = _decode_key($data->{'current'});
    $self->current($current);
    if ($data->{'predecessor'}) {
        my $predecessor = _decode_key($data->{'predecessor'});
        $self->predecessor($predecessor);
    }
    if ($data->{'successor'}) {
        my $successor = _decode_key($data->{'successor'});
        $self->successor($successor);
    }

    return 1;
}

1;
