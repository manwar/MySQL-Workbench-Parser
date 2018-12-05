package MySQL::Workbench::Parser::Column;

# ABSTRACT: A column of the ER model

use strict;
use warnings;

use Moo;
use Scalar::Util qw(blessed);

=head1 METHODS

=cut

our $VERSION = '1.03';

has node => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        blessed $_[0] && $_[0]->isa( 'XML::LibXML::Element' );
    },
);

has table => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        blessed $_[0] && $_[0]->isa( 'MySQL::Workbench::Parser::Table' );
    },
);

=for Pod::Coverage BUILD

=cut

sub BUILD {
    my $self = shift;
    $self->_parse;
}

has name          => ( is => 'rwp' );
has id            => ( is => 'rwp' );
has length        => ( is => 'rwp' );
has datatype      => ( is => 'rwp' );
has precision     => ( is => 'rwp' );
has not_null      => ( is => 'rwp' );
has autoincrement => ( is => 'rwp' );
has default_value => ( is => 'rwp' );
has comment       => ( is => 'rwp' );

=head2 as_hash

return info about a column as a hash

    my %info = $column->as_hash;

returns

    (
        name          => 'id',
        datatype      => 'INT',
        length        => '',
        precision     => '0',
        not_null      => '1',
        autoincrement => '1',
        default_value => '',
    )

=cut

sub as_hash {
    my $self = shift;

    my %info;

    for my $attr ( qw(name length datatype precision not_null autoincrement default_value comment) ) {
        $info{$attr} = $self->$attr();
    }

    return \%info;
}

sub _parse {
    my $self = shift;

    my $node = $self->node;

    my $id = $node->findvalue( '@id' );
    $self->_set_id( $id );

    for my $key ( qw(name length precision comment) ) {
        my $value  = $node->findvalue( './value[@key="' . $key . '"]' );
        my $method = $self->can( '_set_' . $key );
        $self->$method( $value );
    }

    my $datatype_internal = $node->findvalue( './link[@struct-name="db.SimpleDatatype" or @struct-name="db.UserDatatype"]' );
    my $datatype          = $self->table->get_datatype( $datatype_internal );
    $self->_set_datatype( $datatype->{name} );
    $self->_set_length( $datatype->{length} )       if $datatype->{length};
    $self->_set_precision( $datatype->{precision} ) if $datatype->{precision};

    my $not_null = $node->findvalue( './value[@key="isNotNull"]' );
    $self->_set_not_null( $not_null );

    my $auto_increment = $node->findvalue( './value[@key="autoIncrement"]' );
    $self->_set_autoincrement( $auto_increment );

    my $default = $node->findvalue( './value[@key="defaultValue"]' );
    $self->_set_default_value( $default );
}

1;

=head1 ATTRIBUTES

=over 4

=item * autoincrement

=item * comment

=item * datatype

=item * default_value

=item * id

=item * length

=item * name

=item * node

=item * not_null

=item * precision

=item * table

=back

=head1 MISC

=head2 BUILD
