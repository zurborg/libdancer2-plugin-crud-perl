use strictures 1;

package Dancer2::Plugin::CRUD::Documentation;

# ABSTRACT: Use attributes to declare API blueprint documentation for CRUD applications

use Attribute::Handlers;

# VERSION

my $Stash = {};

sub _add_attr_doc {
    my ( $type, $package, $symbol, $referent, $data ) = @_[ 0 .. 3, 5 ];

    my $name = $symbol eq 'ANON' ? undef : *{$symbol}{NAME};

    $Stash->{$referent} //= [];
    $data = $data->[0] if ref $data eq 'ARRAY';
    push @{ $Stash->{$referent} } => {
        package       => $package,
        name          => $name,
        type          => $type,
        documentation => $data,
    };
}

sub _get_attr_doc {
    my ($referent) = @_;
    return unless exists $Stash->{$referent};
    return @{ $Stash->{$referent} };
}

1;

__END__

use JSON         ();
use YAML::Any    ();
use Data::Dumper ();
use Text::API::Blueprint qw(:all);

sub _rpl {
    my ( $re, $str, $rpl ) = @_;
    $rpl //= '';
    $str =~ s{^${re}}{$rpl}eg;
    $str =~ s{${re}$}{$rpl}eg;
    return $str;
}

sub _trim(_) {
    _rpl( qr{\s+}, shift() );
}

sub _indent {
    my ( $str, $n ) = @_;
    $n //= 4;
    my $indent = ' ' x $n;
    $str =~ s{(\r?\n)}{$1.$indent}eg;
    return $indent . $str;
}

sub _flatten {
    my ($str) = @_;
    my ($pre) = ( $str =~ m{^(\s*)\S} );
    return $str unless $pre;
    $str =~ s{^\Q$pre\E}{}rmg;
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

sub _mkheaderhash {
    my $str = shift;
    
    my @lines = map _trim, grep m{\S}, split /\n+/ => $str;
    
    my %headers = map { map _trim, split /:/, 2 } @lines;
    
    return \%headers;
}

=func generate_apiblueprint ($docstack, %options)

For internal use only.

=cut

sub generate_apiblueprint {
    my ( $docstack, %options ) = @_;
    
    my $dump = sub {
        local $Data::Dumper::Purity = 1;
        local $Data::Dumper::Terse  = 1;
        local $Data::Dumper::Indent = 1;
        Data::Dumper::Dumper(@_);
    };

    my %methods = (
        index  => 'GET',
        read   => 'GET',
        create => 'POST',
        update => 'PUT',
        patch  => 'PATCH',
        delete => 'DELETE',
    );

    my $prefix = $options{prefix} || '';

    my $doc = Section(sub {
        
        Meta();
        
        Intro($options{name}, $options{intro});
        
        while ( my $resource = pop @$docstack ) {

            Group($resource->{name}, $resource->{intro});
    
            my $lastp = '';
    
            my %pathmap = _arrayhash(
                map { ( $resource->{$_}->{Path} => $_ ) }
                  grep { exists $resource->{$_} }
                  qw(index create read update patch delete)
            );
    
            foreach my $trigger (qw(index create read update patch delete)) {
                next unless exists $resource->{$trigger};
    
                my $method = $methods{$trigger};
                my $action = $resource->{$trigger};
                my $path   = $prefix . $action->{Path};
    
                if ( $lastp ne $path ) {
                    my $triggers = join ' ' => map ucfirst,
                      @{ $pathmap{ $action->{Path} } };
                    Resource(identifier => $trigger, uri => $path);
                    $lastp = "$path";
                }
    
                Action(identifier => ucfirst($trigger), method => $method);
    
                if ( exists $action->{description} ) {
                    Text($action->{description}->[0]);
                }
                
                my %parameters;

                my @oformats = qw(json yaml dump);
                if ( exists $action->{PathP} ) {
                    push @oformats => $trigger . 'p';
                }
                if ( exists $action->{oformats} ) {
                    @oformats = keys %{ $action->{oformats} };
                }
                if ( @oformats > 1 ) {
                    $parameters{format} = {
                        required => 1,
                        enum => 'string',
                        members => \@oformats
                    };
                }
    
                if ( $action->{hasid} ) {
                    $parameters{$resource->{captvar}} = {
                        required => 1,
                        type => $resource->{idtype},
                    };
                }

                Parameters(%parameters);

                my $request_body;
                if ( exists $action->{request_body} ) {
                    $request_body = $action->{request_body}->[0];
                }
    
                my $request_headers;
                if ( exists $action->{request_headers} ) {
                    $request_headers = _trim( $action->{request_headers}->[0] );
                    $request_headers = _mkheaderhash($request_headers);
                }
    
                my $response_body;
                if ( exists $action->{response_body} ) {
                    $response_body = $action->{response_body}->[0];
                }
    
                my $response_headers;
                if ( exists $action->{response_headers} ) {
                    $response_headers = _trim( $action->{response_headers}->[0] );
                    $response_headers = _mkheaderhash($response_headers);
                }

                my $request_schema;
                if ( exists $action->{request_schema} ) {
                    $request_schema = $json->encode($action->{request_schema}->[0]);
                }

                my $response_schema;
                if ( exists $action->{response_schema} ) {
                    $response_schema = $json->encode($action->{response_schema}->[0]);
                }

                if ( exists $action->{oformats} ) {
                    foreach my $fmt ( keys %{ $action->{oformats} } ) {
    
                        my $ctype = $action->{oformats}->{$fmt} || next;
                        
                        my $npath = ($path =~ s{\Q{format}\E}{$fmt}re);

                        Request($fmt,
                            type => $ctype,
                            (description => "`$npath`")x!!$npath,
                            headers => $request_headers,
                            body => $request_body,
                            schema => $request_schema
                        );
                        
                        Response(200,
                            type => $ctype,
                            headers => $response_headers,
                            body => $response_body,
                            schema => $response_schema,
                        )

                    }

                } else {

                    Request('JSON',
                        type => 'application/json',
                        (description => "`$npath`")x!!$npath,
                        headers => $request_headers,
                        json => $request_body,
                        schema => $request_schema,
                    )

                    Response(200,
                        type => 'application/json',
                        headers => $response_headers,
                        json => $response_body,
                        schema => $response_schema,
                    )

                    Request('YAML',
                        type => 'application/yaml',
                        (description => "`$npath`")x!!$npath,
                        headers => $request_headers,
                        yaml => $request_body,
                        schema => $request_schema,
                    )

                    Response(200,
                        type => 'application/yaml',
                        headers => $response_headers,
                        yaml => $response_body,
                        schema => $response_schema,
                    )

                    Request('DUMP',
                        type => 'application/perl',
                        (description => "`$npath`")x!!$npath,
                        headers => $request_headers,
                        code => $dump->($request_body),
                        lang => 'perl',
                        schema => $request_schema,
                    )

                    Response(200,
                        type => 'application/perl',
                        headers => $response_headers,
                        code => $dump->($response_body),
                        lang => 'perl',
                        schema => $response_schema,
                    )

                }

            }

        }

    }, 0);

    $doc =~ s{(\r?\n)[\t ]+(\r?\n)}{$1.$2}eg;
    return $doc;
}

no warnings 'redefine';

=attr Description

A (possible short) description on what's going on in this action handler

=cut

sub UNIVERSAL::Description : ATTR(CODE,RAWDATA,BEGIN) {
    _add_attr_doc( description => @_ );
}

=attr RequestBody

An example code for the request body. Ordinary perl structure may be used.

=cut

sub UNIVERSAL::RequestBody : ATTR(CODE,BEGIN) {
    _add_attr_doc( request_body => @_ );
}

=attr ResponseBody

An example code for the response body. Ordinary perl structure may be used.

=cut

sub UNIVERSAL::ResponseBody : ATTR(CODE,BEGIN) {
    _add_attr_doc( response_body => @_ );
}

=attr RequestHeaders

List of headers that should be sent with request. (one header per line)

=cut

sub UNIVERSAL::RequestHeaders : ATTR(CODE,RAWDATA,BEGIN) {
    _add_attr_doc( request_headers => @_ );
}

=attr ResponseHeaders

List of headers that appears in the response. (one header per line)

=cut

sub UNIVERSAL::ResponseHeaders : ATTR(CODE,RAWDATA,BEGIN) {
    _add_attr_doc( response_headers => @_ );
}

1;

__END__

=head1 DESCRIPTION

This module enables attributes in order to generate an API blueprint markdown file, with all route handlers including information about I<:id> and I<:format> parameters. Example code for all formats are preformatted. Currently YAML, JSON and Dumper is supported.

B<Important notice>: please keep in mind, that all parentheses B<must> be balanced! This is a limitation in the perl parser, not only in this module.

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

