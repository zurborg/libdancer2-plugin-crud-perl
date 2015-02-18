use strictures 1;

package Dancer2::Plugin::CRUD::Documentation;

# ABSTRACT: Use attributes to declare API blueprint documentation for CRUD applications

use Attribute::Handlers;
use JSON         ();
use YAML::Any    ();
use Data::Dumper ();

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

sub _rpl {
    my ( $re, $str, $rpl ) = @_;
    $rpl //= '';
    $str =~ s{^${re}}{$rpl}eg;
    $str =~ s{${re}$}{$rpl}eg;
    return $str;
}

sub _trim {
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

=func generate_apiblueprint ($docstack, %options)

For internal use only.

=cut

sub generate_apiblueprint {
    my ( $docstack, %options ) = @_;

    my $doc = "FORMAT: 1A\n\n";
    $doc .= "# " . $options{name} . "\n\n" if exists $options{name};
    $doc .= $options{intro} . "\n\n" if exists $options{intro};
    my $json = JSON->new->utf8->pretty->allow_nonref;
    my $yaml = \&YAML::Any::Dump;
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

    while ( my $resource = pop @$docstack ) {
        my $name = $resource->{name};
        $doc .= "# Group $name\n\n";
        $doc .= $resource->{intro} . "\n\n" if $resource->{intro};

        if (0) {    # walk through parents
            my $node = $resource;
            while ( exists $node->{parent} ) {
                $node = $node->{parent};
            }
        }

        my $rupd  = 0;
        my $lastp = '';

        my %pathmap = _arrayhash(
            map { ( $resource->{$_}->{Path} => $_ ) }
              grep { exists $resource->{$_} }
              qw(index create read update patch delete)
        );

        foreach my $trigger (qw(index create read update patch delete)) {
            next unless exists $resource->{$trigger};

            #$dsl->debug(" $name # $trigger ");

            my $method = $methods{$trigger};
            my $action = $resource->{$trigger};
            my $path   = $prefix . $action->{Path};

            if ( $lastp ne $path ) {
                my $triggers = join ' ' => map ucfirst,
                  @{ $pathmap{ $action->{Path} } };
                $doc .= "## $triggers [$path]\n\n";
                $lastp = "$path";
            }

            $doc .= "### " . ucfirst($trigger) . " [$method]\n\n";

            if ( exists $action->{description} ) {
                my $desc = _flatten( $action->{description}->[0] );
                $doc .= "$desc\n\n";
            }

            $doc .= "+ Parameters\n\n";

            my @oformats = qw(json yaml dump);
            if ( exists $action->{PathP} ) {
                push @oformats => $trigger . 'p';
            }

            if ( exists $action->{oformats} ) {
                @oformats = keys %{ $action->{oformats} };
            }
            if ( @oformats > 1 ) {
                $doc .= "    + format (required, string)\n\n";
                $doc .= "        + Values\n\n";
                foreach my $format (@oformats) {
                    $doc .= "            + `$format`\n";
                }
            }
            $doc .= "\n";

            if ( $action->{hasid} ) {
                $doc .=
                    "    + "
                  . $resource->{captvar}
                  . " (required, "
                  . $resource->{idtype} . ")\n";
                $doc .= "\n";
            }

            my $request_body;
            if ( exists $action->{request_body} ) {
                $request_body = $action->{request_body}->[0];
            }

            my $request_headers;
            if ( exists $action->{request_headers} ) {
                $request_headers = _trim( $action->{request_headers}->[0] );
                $request_headers =~ s{\s*(\r?\n)\s*}{$1}eg;
            }

            my $response_body;
            if ( exists $action->{response_body} ) {
                $response_body = $action->{response_body}->[0];
            }

            my $response_headers;
            if ( exists $action->{response_headers} ) {
                $response_headers = _trim( $action->{response_headers}->[0] );
                $response_headers =~ s{\s*(\r?\n)\s*}{$1}eg;
            }

            my $request_schema;
            if ( exists $action->{request_schema} ) {
                my $x = $action->{request_schema}->[0];
                $request_schema = $json->encode($x);
            }

            my $response_schema;
            if ( exists $action->{response_schema} ) {
                $response_schema =
                  $json->encode( $action->{response_schema}->[0] );
            }

            if ( exists $action->{oformats} ) {
                foreach my $fmt ( keys %{ $action->{oformats} } ) {

                    my $ctype = $action->{oformats}->{$fmt} || next;

                    $doc .= "+ Request $fmt ($ctype)\n\n";
                    if ( my $npath = ( $path =~ s{\Q{format}\E}{$fmt}re ) ) {
                        $doc .= "    + `$npath`\n\n";
                    }
                    if ( $request_headers or $request_body ) {
                        $doc .=
                          _indent(
                            "+ Headers\n\n" . _indent( $request_headers, 8 ) )
                          . "\n\n"
                          if $request_headers;
                        $doc .=
                          _indent( "+ Body\n\n" . _indent( $request_body, 8 ) )
                          . "\n\n"
                          if $request_body;
                        $doc .=
                          _indent(
                            "+ Schema\n\n" . _indent( $request_schema, 8 ) )
                          . "\n\n"
                          if $request_schema;
                    }
                    else {
                        $doc .=
                          _indent( "+ Body\n\n" . _indent( "(no content)", 8 ) )
                          . "\n\n";
                    }

                    if ( $response_headers or $response_body ) {
                        $doc .= "+ Response 200 ($ctype)\n\n";
                        $doc .=
                          _indent(
                            "+ Headers\n\n" . _indent( $response_headers, 8 ) )
                          . "\n\n"
                          if $response_headers;
                        $doc .=
                          _indent( "+ Body\n\n" . _indent( $response_body, 8 ) )
                          . "\n\n"
                          if $response_body;
                        $doc .=
                          _indent(
                            "+ Schema\n\n" . _indent( $response_schema, 8 ) )
                          . "\n\n"
                          if $response_schema;
                    }
                    else {
                        $doc .=
                          "+ Response 200 ($ctype)\n\n        no body\n\n";
                    }

                }

            }
            else {

                $doc .= "+ Request JSON (application/json)\n\n";
                if ( my $npath = ( $path =~ s{\Q{format}\E}{json}r ) ) {
                    $doc .= "    + `$npath`\n\n";
                }
                if ( $request_headers or $request_body ) {
                    $doc .=
                      _indent(
                        "+ Headers\n\n" . _indent( $request_headers, 8 ) )
                      . "\n\n"
                      if $request_headers;
                    $doc .=
                      _indent( "+ Body\n\n"
                          . _indent( $json->encode($request_body), 8 ) )
                      . "\n\n"
                      if $request_body;
                    $doc .=
                      _indent( "+ Schema\n\n" . _indent( $request_schema, 8 ) )
                      . "\n\n"
                      if $request_schema;
                }
                else {
                    $doc .=
                      _indent( "+ Body\n\n" . _indent( "// (no content)", 8 ) )
                      . "\n\n";
                }

                if ( $response_headers or $response_body ) {
                    $doc .= "+ Response 200 (application/json)\n\n";
                    $doc .=
                      _indent(
                        "+ Headers\n\n" . _indent( $response_headers, 8 ) )
                      . "\n\n"
                      if $response_headers;
                    $doc .=
                      _indent( "+ Body\n\n"
                          . _indent( $json->encode($response_body), 8 ) )
                      . "\n\n"
                      if $response_body;
                    $doc .=
                      _indent( "+ Schema\n\n" . _indent( $response_schema, 8 ) )
                      . "\n\n"
                      if $response_schema;
                }
                else {
                    $doc .=
"+ Response 200 (application/json)\n\n        // no body\n\n";
                }

                $doc .= "+ Request YAML (text/x-yaml)\n\n";
                if ( my $npath = ( $path =~ s{\Q{format}\E}{yml}r ) ) {
                    $doc .= "    + `$npath`\n\n";
                }
                if ( $request_headers or $request_body ) {
                    $doc .=
                      _indent(
                        "+ Headers\n\n" . _indent( $request_headers, 8 ) )
                      . "\n\n"
                      if $request_headers;
                    $doc .=
                      _indent(
                        "+ Body\n\n" . _indent( $yaml->($request_body), 8 ) )
                      . "\n\n"
                      if $request_body;
                    $doc .=
                      _indent( "+ Schema\n\n" . _indent( $request_schema, 8 ) )
                      . "\n\n"
                      if $request_schema;
                }
                else {
                    $doc .=
                      _indent( "+ Body\n\n" . _indent( "# (no content)", 8 ) )
                      . "\n\n";
                }

                if ( $response_headers or $response_body ) {
                    $doc .= "+ Response 200 (text/x-yaml)\n\n";
                    $doc .=
                      _indent(
                        "+ Headers\n\n" . _indent( $response_headers, 8 ) )
                      . "\n\n"
                      if $response_headers;
                    $doc .=
                      _indent(
                        "+ Body\n\n" . _indent( $yaml->($response_body), 8 ) )
                      . "\n\n"
                      if $response_body;
                    $doc .=
                      _indent( "+ Schema\n\n" . _indent( $response_schema, 8 ) )
                      . "\n\n"
                      if $response_schema;
                }
                else {
                    $doc .=
                      "+ Response 200 (text/x-yaml)\n\n        # no body\n\n";
                }

                $doc .= "+ Request DUMP (text/x-perl)\n\n";
                if ( my $npath = ( $path =~ s{\Q{format}\E}{dump}r ) ) {
                    $doc .= "    + `$npath`\n\n";
                }
                if ( $request_headers or $request_body ) {
                    $doc .=
                      _indent(
                        "+ Headers\n\n" . _indent( $request_headers, 8 ) )
                      . "\n\n"
                      if $request_headers;
                    $doc .=
                      _indent(
                        "+ Body\n\n" . _indent( $dump->($request_body), 8 ) )
                      . "\n\n"
                      if $request_body;
                    $doc .=
                      _indent( "+ Schema\n\n" . _indent( $request_schema, 8 ) )
                      . "\n\n"
                      if $request_schema;
                }
                else {
                    $doc .=
                      _indent( "+ Body\n\n" . _indent( "# (no content)", 8 ) )
                      . "\n\n";
                }

                if ( $response_headers or $response_body ) {
                    $doc .= "+ Response 200 (text/x-perl)\n\n";
                    $doc .=
                      _indent(
                        "+ Headers\n\n" . _indent( $response_headers, 8 ) )
                      . "\n\n"
                      if $response_headers;
                    $doc .=
                      _indent(
                        "+ Body\n\n" . _indent( $dump->($response_body), 8 ) )
                      . "\n\n"
                      if $response_body;
                    $doc .=
                      _indent( "+ Schema\n\n" . _indent( $response_schema, 8 ) )
                      . "\n\n"
                      if $response_schema;
                }
                else {
                    $doc .=
                      "+ Response 200 (text/x-perl)\n\n        # no body\n\n";
                }

                if ( exists $action->{PathP} ) {

                    $doc .= "+ Request JSONP\n\n";
                    if ( my $npath =
                        ( $path =~ s{\Q{format}\E}{${trigger}p}r ) )
                    {
                        $doc .=
                          "    + GET `$npath" . "{?callback,headers,data}`\n\n";
                    }

                    $doc .=
                      _indent( "+ Body\n\n" . _indent( "// (no content)", 8 ) )
                      . "\n\n";

                    $doc .= "+ Response 200 (text/javascript)\n\n";
                    $doc .= _indent(
                        "+ Body\n\n"
                          . _indent(
                            "callback(\n"
                              . _indent( $json->encode($response_body) )
                              . "\n)",
                            8
                          )
                      )
                      . "\n\n"
                      if $response_body;
                    $doc .=
                      _indent( "+ Schema\n\n" . _indent( $response_schema, 8 ) )
                      . "\n\n"
                      if $response_schema;

                }

            }

            if (0) {

                # TODO

                $doc .= "## GET [" . $action->{PathP} . "]\n";
                $doc .= "JSONP equalivent $trigger method for `$method "
                  . $action->{Path} . "`\n\n";

                $doc .= "+ Parameters\n\n";
                $doc .= "    + callback (required, string) \n\n";
                $doc .= "\n";
                if ( $action->{hasid} ) {
                    $doc .= "    + id (required, any)\n";
                    $doc .= "\n";
                }

                $doc .= "+ Response 200 (text/javascript)\n\n";
                $doc .=
                  _indent( "callback(\n"
                      . _indent( $json->encode($response_body) )
                      . "\n);" )
                  . "\n\n"
                  if $response_body;

            }
        }

    }

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

B<Important notice>: please keep in mind, that all parenthesis B<must> be balanced! This is a limitation in the perl parser, not only in this module.

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

