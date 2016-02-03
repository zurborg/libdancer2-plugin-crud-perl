use strictures 2;

package Dancer2::Plugin::CRUD::Documentation;

use Dancer2::Plugin::CRUD::Constants;

# ABSTRACT: Use attributes to declare API blueprint documentation for CRUD applications

=attr Description

A (possible short) description on what's going on in this action handler

=attr RequestBody

An example code for the request body. Ordinary perl structure may be used.

=attr ResponseBody

An example code for the response body. Ordinary perl structure may be used.

=attr RequestHeaders

List of headers that should be sent with request. (one header per line)

=attr ResponseHeaders

List of headers that appears in the response. (one header per line)

=cut

use Attribute::Universal 0.003;

use Text::API::Blueprint qw(Compile Concat);

use JSON ();
use YAML ();
use Data::Dumper ();

# VERSION

my $Stash = {};

sub import {
    my $caller = scalar caller;
    Attribute::Universal->import_into($caller
    ,   Description     => 'CODE,RAWDATA,BEGIN'
    ,   RequestBody     => 'CODE,BEGIN'
    ,   ResponseBody    => 'CODE,BEGIN'
    ,   RequestHeader   => 'CODE,RAWDATA,BEGIN'
    ,   ResponseHeader  => 'CODE,RAWDATA,BEGIN'
    );
    return;
}

=for Pod::Coverage ATTRIBUTE

=cut

sub ATTRIBUTE {
    my $hash = Attribute::Universal::to_hash(@_);
    my $referent = delete $hash->{referent};
    $Stash->{$referent} //= [];
    push @{ $Stash->{$referent} } => $hash;
}

sub _get_attr_doc {
    my ($referent) = @_;
    return unless exists $Stash->{$referent};
    return @{ $Stash->{$referent} };
}

sub _arrayhash {
    my %hash;
    while (@_) {
        my ( $key, $val ) = ( shift, shift );
        next unless defined $key;
        $hash{$key} //= [];
        push @{ $hash{$key} } => $val;
    }
    return %hash;
}

=func generate_apiblueprint ($docstack, %options)

For internal use only.

=cut

sub _apib_assets {
    my ($def) = @_;
    my $assets = [];
    if (exists $def->{iformats}) {
        return [],
    }
    if (exists $def->{oformats}) {
        return [],
    }

    my @RequestHeaders  = map { m{^\s*([^:]+?)\s*:\s*(.+?)\s*$}s ? ($1, $2) : () } @{ $def->{RequestHeader} };
    my @ResponseHeaders = map { m{^\s*([^:]+?)\s*:\s*(.+?)\s*$}s ? ($1, $2) : () } @{ $def->{ResponseHeader} };

    my @RequestBody  = ref $def->{RequestBody}  ? @{$def->{RequestBody}}  : undef;
    my @ResponseBody = ref $def->{ResponseBody} ? @{$def->{ResponseBody}} : undef;

    foreach my $data (@RequestBody) {
        push @$assets => ('Request JSON' => {
            type => 'application/json',
            (json => $data) x!!defined$data,
            headers => \@RequestHeaders,
        });
    }

    foreach my $data (@ResponseBody) {
        push @$assets => ('Response 200' => {
            type => 'application/json',
            (json => $data) x!!defined$data,
            headers => \@ResponseHeaders,
        });
    }

    foreach my $data (@RequestBody) {
        push @$assets => ('Request YAML' => {
            type => 'text/yaml',
            (yaml => $data) x!!defined$data,
            headers => \@RequestHeaders,
        });
    }

    foreach my $data (@ResponseBody) {
        push @$assets => ('Response 200' => {
            type => 'text/yaml',
            (yaml => $data) x!!defined$data,
            headers => \@ResponseHeaders,
        });
    }

    return $assets;
}

sub _apib_resource {
    my ($method, $def, $res) = @_;
    my @captvars = map {( $_ => {
        type => 'string',
        example => 123,
    })} @{$res->{captvars}};
    if ($def->{hasid}) {
        push @captvars => ($res->{captvar} => {
            type => 'string',
            example => 456,
        });
    }
    unless (ref $def->{oformats} and keys %{$def->{oformats}} == 1) {
        my %formats = (
            json => 'application/json',
            yml => 'text/yaml',
        );
        if (ref $def->{oformats}) {
            %formats = %{$def->{oformats}};
            map { $formats{$_} //= $_ } keys %formats;
        }
        push @captvars => (
            format => {
                enum => 'string',
                members => [ map {( $_ => $formats{$_} )} sort keys %formats ],
            }
        );
    }

    my @desc;

    if (my $schema = ref ($def->{schema}) ? Text::API::Blueprint::_json($def->{schema}) : undef) {
        push @desc => 'Request Schema';
        push @desc => Text::API::Blueprint::Code($schema);
    }


    return {
        #identifier => $method,
        uri => $def->{Path},
        description => Concat(@{$def->{Description}}),
        parameters => [
            @captvars,
        ],
        actions => [{
            description => Concat(@desc),
            identifier => ucfirst($method),
            method => uc($Dancer2::Plugin::CRUD::Constants::trigger_to_method{$method}),
            assets => _apib_assets($def),
        }]
    };
}

sub _apib_resources {
    my $doc = shift;
    my $resources = [];
    foreach my $method (qw(index create read update patch delete)) {
        next unless exists $doc->{$method} and defined $doc->{$method} and ref $doc->{$method} eq 'HASH' and keys %{$doc->{$method}};
        push @$resources => _apib_resource($method, $doc->{$method}, $doc);
    }
    return $resources;
}

sub _apib_groups {
    my $docs = shift;
    my $groups = [];
    foreach my $doc (@$docs) {
        push @$groups => (
            $doc->{name},
            _apib_resources($doc),
        );
    }
    return $groups;
}

sub generate_apiblueprint {
    my ($docs, %info) = @_;
    my $groups = _apib_groups($docs);
    my $Compile = {
        name => 'Title of generated API blueprint file',
        description => "And the description of it",
        %info,
        groups => $groups,
    };
    return Compile($Compile);
}

1;

__END__

=head1 DESCRIPTION

This module enables attributes in order to generate an API blueprint markdown file, with all route handlers including information about I<:id> and I<:format> parameters. Example code for all formats are preformatted. Currently L<YAML>, L<JSON> and L<Data::Dumper> is supported. L<CBOR|CBOR::XS> is a binary format and there is no AST renderer available so its not possible to display a CBOR output.

B<Important notice>: please keep in mind, that all parenthesis B<must> be balanced! This is a limitation of the perl parser, not only of this module.

=head1 SYNOPSIS

    use Dancer2::Plugin::CRUD;
    use Dancer2::Plugin::CRUD::Documentation;

    resource("foo",
        index => sub
            :Description(
                Get a list of all foos
            )
            :ResponseBody(
                [{
                    id => 1,
                    name => 'Alice',
                },{
                    id => 2,
                    name => 'Bob',
                }]
            )
        { ... }
    )

