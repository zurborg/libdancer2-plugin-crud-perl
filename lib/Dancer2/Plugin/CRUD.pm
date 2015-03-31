use strictures 1;

package Dancer2::Plugin::CRUD;

# ABSTRACT: A plugin for writing RESTful apps with Dancer

use Dancer2::Plugin;
use Carp qw(croak confess);
use Sub::Name qw(subname);
use Text::Pluralize ();
use feature qw(fc);
use Class::Method::Modifiers ();
use Class::Load qw(try_load_class);
use Attribute::Handlers;
use Dancer2::Plugin::CRUD::Documentation ();
use Dancer2::Plugin::CRUD::Constants qw(:all);
use Scalar::Util qw(blessed);

# VERSION

my $stack = [];

my $Stash = {};

my $docstack = [];

sub _pluralize {
    my $str = shift;
    return ( $str, $str ) unless $str =~ m{[\(\)\|\{\}]};
    return (
        Text::Pluralize::pluralize( $str => 1 ),
        Text::Pluralize::pluralize( $str => 2 )
    );
}

sub _concat {
    join '' => @_;
}

sub _fceq {
    return unless @_ == 2;
    fc( shift || '' ) eq fc( pop || '' );
}

sub _fcne {
    return unless @_ == 2;
    fc( shift || '' ) ne fc( pop || '' );
}

sub _camelize {
    my $str = lc(shift);
    $str =~ s{_([^_]+)}{ucfirst($1)}sexg;
    return ucfirst($str);
}

sub _add_attribute {
    my ( $type, $package, $symbol, $referent, $data ) = @_[ 0 .. 3, 5 ];

    $Stash->{$referent} //= {};
    $Stash->{$referent}->{$type} //= [];

    push @{ $Stash->{$referent}->{$type} } => ref $data eq 'ARRAY'
      ? @$data
      : $data;
}

sub _get_attributes {
    my ($referent) = @_;
    return () unless exists $Stash->{$referent};
    return %{ $Stash->{$referent} };
}

sub _set_serializer {
    my ( $app, $serializer ) = @_;

    my $cur = $app->response->serializer;

    if ( defined $serializer and not ref $serializer ) {
        my $class = "Dancer2::Serializer::$serializer";
        if ( try_load_class($class) ) {
            $serializer = $class->new;
        }
        else {
            die _throw( $app, 'Unsupported Media Type', 415 );
        }
    }

    if (
        ( not defined $cur and not defined $serializer )
        or (    defined $cur
            and defined $serializer
            and ref($cur) eq ref($serializer) )
      )
    {
        return;
    }

    my %R = %{ $app->response };
    if ( defined $serializer ) {
        $R{serializer} = $serializer;
    }
    else {
        delete $R{serializer};
    }

    my $R = Dancer2::Core::Response->new(%R);

    $app->set_response($R);
}

sub _throw {
    my ( $app, $message, $status ) = @_;

    my $serializer = $app->response->serializer;

    my $err = Dancer2::Core::Error->new(
        ( message    => $message    ),
        ( app        => $app        ),
        ( status     => $status     ) x !!$status,
        ( serializer => $serializer ) x !!$serializer,
    )->throw;

    $app->has_with_return && $app->with_return->($err);

    return $err;
}

sub _build_sub {
    my ( $dsl, $method, $sub, %opts ) = @_;
    my %validations =
      map { ( $_->{captvar} => $_->{validate} ) }
      grep { $_->{scope} eq 'single_id' and exists $_->{validate} } @$stack;
    my @captures = map { $_->{captvar} } grep { exists $_->{captvar} } @$stack;
    my @chains =
      map { [ $_->{chain}, $_->{captvar} ] }
      grep { ref $_->{chain} eq 'CODE' }

      #grep { $_->{scope} eq 'single_id' }
      @$stack;
    my $cfg = $stack->[-1];

    my $schema = $opts{schema};
    $schema = $schema->[0] if ref $schema eq 'ARRAY';
    if ( ref $schema eq 'HASH' and try_load_class('JSON::Schema') ) {
        $schema = JSON::Schema->new($schema);
    }
    else {
        $schema = undef;
    }

    return sub {
        my $app      = shift;
        my $captures = $app->request->captures || {};
        my %params   = map { ( $_ => $captures->{$_} ) } @captures;

        eval {
            my $serializer = $app->response->serializer;
            if (   !$opts{dont_serialize}
                and $serializer
                and not $app->request->has_serializer )
            {
                $app->request->{data} =
                  $serializer->deserialize( $app->request->body );
            }

            foreach my $captvar ( keys %validations ) {
                my $validatesub = $validations{$captvar};
                next unless ref $validatesub eq 'CODE';
                if ( my @error = $validatesub->( $app, $params{$captvar} ) ) {
                    my ( $text, $code ) = @error;
                    next unless defined $text;
                    $code //= 500;
                    return _throw( $app, $text, $code );
                }
            }

            foreach my $pair (@chains) {
                my ( $sub, $captvar ) = @$pair;
                $sub->( $app, $params{ $captvar || '' } );
            }

            if ($schema) {
                my $result = $schema->validate( $app->request->data );
                unless ($result) {
                    my $msg = join ', ',
                      map { $_->property . ': ' . $_->message } $result->errors;
                    return _throw( $app, $msg, 400 );
                }
            }
        };
        return _throw( $app, $@, 500 ) if $@;

        my ( $code, $data );

        eval { ( $code, $data ) = $sub->( $app, %params ); };
        return _throw( $app, $@, 500 ) if $@;

        if ( defined $code and not ref $code and $code =~ m{^\d{3}$} ) {
            $app->response->status($code);
        }
        else {
            $data = $code;
        }

        $data //= '';

        if ( ref $data eq 'CODE' ) {
            return if _fceq( $app->request->method => 'HEAD' );
            $data = $data->() || '';
        }

        return $data;
    };
}

sub _get_documentation {
    my ($coderef) = @_;
    my @doc = Dancer2::Plugin::CRUD::Documentation::_get_attr_doc($coderef);
    return unless @doc;
    my %doc;
    foreach my $item (@doc) {
        $doc{ $item->{type} } //= [];
        push @{ $doc{ $item->{type} } } => $item->{documentation};
    }
    return \%doc;
}

sub _getsub {
    my ( $resources, $action, $sub ) = @_;
    return $sub if ref $sub eq 'CODE';
    die "handler for action $action not defined" unless defined $sub;
    die "unknown handler for action $action: $sub"
      unless _fceq( $sub => 'dispatch' );
    my $pkg = ( caller(2) )[0];
    map { $pkg .= '::' . _camelize($_) } @$resources;
    $sub = "${pkg}::${action}_action";
    return \&$sub;
}

register resource => (
    sub {
        my ( $dsl, $resource, %options ) = @_;

        my ( $single, $plural ) = _pluralize($resource);

        my $idregex = delete( $options{idregex} ) || qr{[^\/\.\:\?]+};

        my $captvar = delete( $options{captvar} ) || "${single}_id";

        my $documentation = {
            captvar => $captvar,
            idtype  => "$idregex",
            intro   => delete( $options{description} ),
        };

        if ( _fcne( ref($idregex) => 'regexp' ) ) {
            $idregex = $RE{$idregex}
              || confess("unknown idregex type: $idregex");
        }
        $idregex = qr{ (?<$captvar> $idregex ) }xsi;

        my $fmtregex = join '|', map quotemeta, keys %ext_to_fmt;

        my $prefix =
          _concat map { $_->{prefix} } grep { exists $_->{prefix} } @$stack;
        my $pathbase =
          _concat map { $_->{path} } grep { exists $_->{path} } @$stack;

        my %routes;
        my @routes;

        my $add_route = sub {
            my ( $regexp, $action, $coderef ) = @_;
            my $key    = qr{^$prefix$regexp$}s;
            my $method = $trigger_to_method{$action};
            push @routes => $dsl->app->add_route(
                regexp  => $key,
                method  => $method,
                options => {},
                code    => $coderef,
            );
            push @routes => $dsl->app->add_route(
                regexp  => $key,
                method  => 'head',
                options => {},
                code    => sub { $coderef->(@_); return },
            ) if $method eq 'get';
            $routes{$key} //= [$key];
            push @{ $routes{$key} } => $method;
        };

        my $cfg = {
            single        => $single,
            plural        => $plural,
            validate      => delete( $options{validate} ),
            documentation => $documentation,
        };
        push @$stack => $cfg;

        $documentation->{name} =
          join ' of ' => reverse map { $_->{single} } @$stack;

        my $resources = [ map { $_->{single} } @$stack ];

        ### single_id ###
        $cfg->{scope}   = 'single_id';
        $cfg->{chain}   = delete $options{chain_id};
        $cfg->{captvar} = $captvar;
        if ( exists $options{single_id} ) {
            my $sub = delete $options{single_id};
            $cfg->{prefix} = qr{ /+ \Q$single\E / $idregex }xsi;
            $cfg->{path}   = "/$single/{$captvar}";
            $sub->();
            delete $cfg->{prefix};
            delete $cfg->{path};
        }

        foreach my $method (qw(read update patch delete)) {
            if ( exists $options{$method} ) {
                $cfg->{method} = $method;
                my $coderef =
                  _getsub( $resources, $method, delete $options{$method} );
                my $doc     = _get_documentation($coderef);
                my %actopts = _get_attributes($coderef);

                my $lfmtregex = $fmtregex;

                $documentation->{$method} = {
                    %$doc,
                    Path => "$pathbase/$single/{$captvar}.{format}",
                    PathP =>
                      "$pathbase/$single/{$captvar}.${method}p?{callback}",
                    hasid => 1,
                    opts  => \%actopts,
                  }
                  if $doc;

                if ( $doc and exists $actopts{iformat} ) {
                    my %formats = map { ( $_->[0] => $_->[1] || undef ) } map {
                        m{^ \s* (\S+) (?: \s+ \( \s* (\S*) \s* \) )? \s* $}x
                          ? [ $1, $2 ]
                          : [$_]
                    } @{ $actopts{iformat} };
                    $documentation->{$method}->{iformats} = \%formats;
                }

                if ( exists $actopts{oformat} ) {
                    my %formats = map { ( $_->[0] => $_->[1] || undef ) } map {
                        m{^ \s* (\S+) (?: \s+ \( \s* (\S*) \s* \) )? \s* $}x
                          ? [ $1, $2 ]
                          : [$_]
                    } @{ $actopts{oformat} };
                    my @formats = keys %formats;
                    $lfmtregex = join '|' => map quotemeta, @formats;
                    $lfmtregex = qr{(?:$lfmtregex)}x;
                    if ($doc) {
                        $documentation->{$method}->{oformats} = \%formats;
                        if ( @formats == 1 ) {
                            $documentation->{$method}->{Path} =~
                              s{\Q{format}\E}{$formats[0]}egi;
                        }
                    }
                }

                my $sub = _build_sub(
                    $dsl,
                    $method        => $coderef,
                    schema         => delete( $actopts{schema} ),
                    dont_serialize => exists $actopts{iformat},
                );
                $add_route->(
                    qr{
                        /+ \Q$single\E
                        /+ $idregex
                        (?:/+|\.(?<format>$lfmtregex))
                    }xs,
                    $method,
                    $sub,
                );
                if (    $options{jsonp}
                    and not exists $actopts{iformat}
                    and not exists $actopts{oformat} )
                {
                    $dsl->app->add_route(
                        regexp => qr{^
                            $prefix
                            /+ \Q$single\E
                            /+ $idregex
                            \.(?<format>${method}p)
                        $}xsi,
                        method  => 'get',
                        options => {},
                        code    => $sub
                    );
                }
                else {
                    delete $documentation->{$method}->{PathP} if $doc;
                }
                delete $cfg->{method};
            }

        }

        delete $cfg->{captvar};
        delete $cfg->{chain};

        ### single ###
        $cfg->{scope} = 'single';
        $cfg->{chain} = delete $options{chain};
        if ( exists $options{single} ) {
            my $sub = delete $options{single};
            $cfg->{prefix} = qr{ /+ \Q$single\E }xsi;
            $cfg->{path}   = "/$single";
            $sub->();
            delete $cfg->{prefix};
            delete $cfg->{path};
        }

        foreach my $method (qw(create)) {
            if ( exists $options{$method} ) {
                $cfg->{method} = $method;
                my $coderef =
                  _getsub( $resources, $method, delete $options{$method} );
                my $doc     = _get_documentation($coderef);
                my %actopts = _get_attributes($coderef);

                my $lfmtregex = $fmtregex;

                $documentation->{$method} = {
                    %$doc,
                    Path  => "$pathbase/$single.{format}",
                    PathP => "$pathbase/$single.${method}p?{callback}",
                    hasid => 0,
                    opts  => \%actopts,
                  }
                  if $doc;

                if ( $doc and exists $actopts{iformat} ) {
                    my %formats = map { ( $_->[0] => $_->[1] || undef ) } map {
                        m{^ \s* (\S+) (?: \s+ \( \s* (\S*) \s* \) )? \s* $}x
                          ? [ $1, $2 ]
                          : [$_]
                    } @{ $actopts{iformat} };
                    $documentation->{$method}->{iformats} = \%formats;
                }

                if ( exists $actopts{oformat} ) {
                    my %formats = map { ( $_->[0] => $_->[1] || undef ) } map {
                        m{^ \s* (\S+) (?: \s+ \( \s* (\S*) \s* \) )? \s* $}x
                          ? [ $1, $2 ]
                          : [$_]
                    } @{ $actopts{oformat} };
                    my @formats = keys %formats;
                    $lfmtregex = join '|' => map quotemeta, @formats;
                    $lfmtregex = qr{(?:$lfmtregex)}x;
                    if ($doc) {
                        $documentation->{$method}->{oformats} = \%formats;
                        if ( @formats == 1 ) {
                            $documentation->{$method}->{Path} =~
                              s{\Q{format}\E}{$formats[0]}egi;
                        }
                    }
                }

                my $sub = _build_sub(
                    $dsl,
                    $method => $coderef,
                    schema  => delete( $actopts{schema} )
                );
                $add_route->(
                    qr{
                        /+ \Q$single\E
                        (?:/+|\.(?<format>$lfmtregex))
                    }xs,
                    $method,
                    $sub,
                );
                if ( $options{jsonp} and not exists $actopts{format} ) {
                    $dsl->app->add_route(
                        regexp => qr{^
                            $prefix
                            /+ \Q$single\E
                            \.(?<format>${method}p)
                        $}xsi,
                        method  => 'get',
                        options => {},
                        code    => $sub
                    );
                }
                else {
                    delete $documentation->{$method}->{PathP} if $doc;
                }
                delete $cfg->{method};
            }

        }

        ### plural ###
        $cfg->{scope} = 'plural';
        if ( exists $options{plural} ) {
            my $sub = delete $options{plural};
            $cfg->{prefix} = qr{ /+ \Q$plural\E }xsi;
            $cfg->{path}   = "/$plural";
            $sub->();
            delete $cfg->{prefix};
            delete $cfg->{path};
        }

        foreach my $method (qw(index)) {
            if ( exists $options{$method} ) {
                $cfg->{method} = $method;
                my $coderef =
                  _getsub( $resources, $method, delete $options{$method} );
                my $doc     = _get_documentation($coderef);
                my %actopts = _get_attributes($coderef);

                my $lfmtregex = $fmtregex;

                $documentation->{$method} = {
                    %$doc,
                    Path  => "$pathbase/$plural.{format}",
                    PathP => "$pathbase/$plural.${method}p?{callback}",
                    hasid => 0,
                    opts  => \%actopts,
                  }
                  if $doc;

                if ( $doc and exists $actopts{iformat} ) {
                    my %formats = map { ( $_->[0] => $_->[1] || undef ) } map {
                        m{^ \s* (\S+) (?: \s+ \( \s* (\S*) \s* \) )? \s* $}x
                          ? [ $1, $2 ]
                          : [$_]
                    } @{ $actopts{iformat} };
                    $documentation->{$method}->{iformats} = \%formats;
                }

                if ( exists $actopts{oformat} ) {
                    my %formats = map { ( $_->[0] => $_->[1] || undef ) } map {
                        m{^ \s* (\S+) (?: \s+ \( \s* (\S*) \s* \) )? \s* $}x
                          ? [ $1, $2 ]
                          : [$_]
                    } @{ $actopts{oformat} };
                    my @formats = keys %formats;
                    $lfmtregex = join '|' => map quotemeta, @formats;
                    $lfmtregex = qr{(?:$lfmtregex)}x;
                    if ($doc) {
                        $documentation->{$method}->{oformats} = \%formats;
                        if ( @formats == 1 ) {
                            $documentation->{$method}->{Path} =~
                              s{\Q{format}\E}{$formats[0]}egi;
                        }
                    }
                }

                my $sub = _build_sub(
                    $dsl,
                    $method => $coderef,
                    schema  => delete( $actopts{schema} )
                );
                $add_route->(
                    qr{
                        /+ \Q$plural\E
                        (?:/+|\.(?<format>$lfmtregex))
                    }xs,
                    $method,
                    $sub,
                );
                if ( $options{jsonp} and not exists $actopts{format} ) {
                    $dsl->app->add_route(
                        regexp => qr{^
                            $prefix
                            /+ \Q$plural\E
                            \.(?<format>${method}p)
                        $}xsi,
                        method  => 'get',
                        options => {},
                        code    => $sub
                    );
                }
                else {
                    delete $documentation->{$method}->{PathP} if $doc;
                }
                delete $cfg->{method};
            }

        }

        delete $cfg->{scope};
        delete $cfg->{chain};

        pop @$stack;

        foreach my $route ( keys %routes ) {
            my $regexp = shift @{ $routes{$route} };
            my @methods = map uc, @{ $routes{$route} };
            push @routes => $dsl->app->add_route(
                regexp  => $regexp,
                method  => 'options',
                options => {},
                code    => sub {
                    my $app = shift;
                    $app->response->header( Allow => join ',', @methods );
                }
            );
        }

        if (@$stack) {
            $documentation->{parent} = $stack->[-1]->{documentation};
        }

        push @$docstack => $documentation;

        return @routes;
    }
  ),
  { is_global => 1 };

our %RAWDOC;

register publish_apiblueprint => (
    sub {
        my ( $dsl, $path, %options ) = @_;

        my $id = delete $options{id};

        my $doc = Dancer2::Plugin::CRUD::Documentation::generate_apiblueprint(
            [ reverse @$docstack ], %options );

        $RAWDOC{$id} = $doc if $id;

        return $dsl->get(
            qr{^ \Q$path\E \. (?<format> md ) $}x => sub {
                my $app = shift;

                my $format = $app->request->captures->{format};
                if ( $format eq 'md' ) {
                    return $doc;
                }
                else {
                    _throw( $app, "unsupported format requested: $format",
                        404 );
                }
            }
        );

    },
    { is_global => 1 }
);

Class::Method::Modifiers::around(
    'Dancer2::Core::DSL::_normalize_route' => sub {
        my ( $orig, $dsl, $methods, $regexp, @rest ) = @_;
        if (@$stack) {
            my $prefix =
              _concat map { $_->{prefix} } grep { exists $_->{prefix} } @$stack;
            $regexp = qr{$prefix$regexp};
        }
        $orig->( $dsl, $methods, $regexp, @rest );
    }
);

on_plugin_import {
    my $dsl = shift;
    $dsl->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before',
            code => sub {
                my $app = shift;
                return
                  unless $app->request->method =~
                  qr{^(?: get | post | put | patch | delete )$}xi;

                my $format;

                if ( $dsl->captures ) {
                    $format = $dsl->captures->{'format'};
                }

                unless ($format) {
                    $format = $dsl->app->request->content_type;
                }

                unless ($format) {
                    return _set_serializer( $app, undef );
                }

                my $serializer;

                if ( $format =~
                    m{^(index|read|create|update|patch|delete)p$}xsi )
                {
                    $dsl->params->{'method'} = fc($1);
                    $dsl->params->{'format'} = 'jsonp';
                    $format                  = $dsl->params->{'format'};
                    $serializer              = 'JSONP';
                }
                elsif ( $format =~ m{^([a-z0-9-_]+/[a-z0-9-_\+]+)(?:;.*)?$}xsi )
                {
                    $format = $type_to_fmt{ fc($1) } || $format;
                }

                # TODO: Access:-field? (via HTTP::Negotiate)

                $serializer //= $ext_to_fmt{$format};

                unless ($serializer) {
                    return _set_serializer( $app, undef );
                }

                # TODO: RFC 5988 ?

                return _set_serializer( $app, $serializer );
            },
        ),
    );
};

register define_serializer => (
    sub {
        my ( $dsl, $module, %options ) = @_;
        $options{extensions} //= [ lc $module ];
        $options{mime_types} //= [ 'application/x-' . lc($module) ];
        my $name = blessed $module;
        if (defined $name) {
            die "$name is not a member of the Dancer2 serializer role" unless $module->isa('Dancer2::Core::Role::Serializer');
        } else {
            $name = "Dancer2::Serializer::$module";
        }
        foreach my $extension ( @{ delete $options{extensions} } ) {
            $Dancer2::Plugin::CRUD::Constants::ext_to_fmt{$extension} = $name;
        }
        foreach my $mime_type ( @{ delete $options{mime_types} } ) {
            $Dancer2::Plugin::CRUD::Constants::type_to_fmt{$mime_type} = $name;
        }
    }
);

register_plugin;

no warnings 'redefine';

=attr Format

Specify another format for the given action. Disables any (de)serializer.

    resource("photo",
        index => sub :Format(png) :Format(jpg) {
            # matches only /photo.png and /photo.jpg
            my $photo = request->body;
        }
    );

A content-type for the L<documentation|Dancer2::Plugin::CRUD::Documentation> may be given in parantheses, too.

    resource("photo",
        index => sub :Format(png (image/png)) { ... }
    );

=cut

sub UNIVERSAL::Format : ATTR(CODE,RAWDATA,BEGIN) {
    _add_attribute( iformat => @_ );
    _add_attribute( oformat => @_ );
}

sub UNIVERSAL::InputFormat : ATTR(CODE,RAWDATA,BEGIN) {
    _add_attribute( iformat => @_ );
}

sub UNIVERSAL::OutputFormat : ATTR(CODE,RAWDATA,BEGIN) {
    _add_attribute( oformat => @_ );
}

=attr RequestSchema

Validation schema for the request message body. Must be valid in accordance to the L<JSON Validation Schema|http://json-schema.org/latest/json-schema-validation.html>.

When L<JSON::Schema> is available, incomming data will be automagically validated againt the request schema.

=cut

sub UNIVERSAL::RequestSchema : ATTR(CODE,BEGIN) {
    _add_attribute( schema => @_ );
    Dancer2::Plugin::CRUD::Documentation::_add_attr_doc( request_schema => @_ );
}

1;

__END__

=head1 DESCRIPTION

This plugin is a complete framework for writing RESTful CRUD appliations. CRUD stands for the four basic database operations: I<c>reate, I<r>ead, I<u>pdate and I<d>elete. (for the sake of completeness two more operations are available: I<patch> and I<index>.)

There are lots of features, like validation rules, chaining actions, mutual serializer and api blueprint documentation.

=head1 SYNOPSIS

    use Dancer2::Plugin::CRUD;

    resource('person',
        create => sub {
            my $app = shift;
        },
        read   => sub {
            my ($app, %param) = @_;
            my $person_id = $param{person_id};
        },
        update => sub {
            my ($app, %param) = @_;
            my $person_id = $param{person_id};
        },
        delete => sub {
            my ($app, %param) = @_;
            my $person_id = $param{person_id};
        },
    );

=method resource ($resource_name, %options)

This keyword defines a resource.

C<$resource_name> is either a simple word, like I<person> or I<item> naming the resource for which trigger action will be created. C<$resource_name> can also be a pluralizable like I<person(s)> or I<item{|s|}>. See L<Text::Pluralize> for more information. The plural name will be used for the I<index> operation, the singular name for all other actions. When no pluralzation is requested, the plural and the singular name equals to the resource name.

Every action route will be created with a format identifier appended. Currently the following formats are supported by L<Dancer2>:

=over 4

=item * YAML

Recognized by suffixes I<.yml> and I<.yaml> and processed by L<Dancer2::Serializer::YAML>.

=item * JSON

Recognized by suffixes I<.jsn> and I<.json> and processed by L<Dancer2::Serializer::JSON>.

=item * Dumper

Recognized by suffixes I<.dmp> and I<.dump> and processed by L<Dancer2::Serializer::Dumper>.

=item * CBOR

Recognized by suffixes I<.cbr> and I<.cbor> and processed by L<Dancer2::Serializer::CBOR>.

=back

More formats like CBOR and XML will be supported in future.

C<%options> accepts the following keywords:

=over 4

=item I<index>

Creates a route for GET I</plural_resource_name.:format>.

    resource("foo",
        index => sub {
            my $app = shift;
        }
    )

=item I<create>

Creates a route for POST I</singular_resource_name.:format>.

    resource("foo",
        create => sub {
            my $app = shift;
        }
    )

=item I<read>

Creates a route for GET I</singular_resource_name/:id.:format>.

    resource("foo",
        read => sub {
            my ($app, %param) = @_;
            my $foo_id = $param{foo_id};
        }
    )

=item I<update>

Creates a route for PUT I</singular_resource_name/:id.:format>.

    resource("foo",
        update => sub {
            my ($app, %param) = @_;
            my $foo_id = $param{foo_id};
        }
    )

=item I<patch>

Creates a route for PATCH I</singular_resource_name/:id.:format>.

    resource("foo",
        patch => sub {
            my ($app, %param) = @_;
            my $foo_id = $param{foo_id};
        }
    )

=item I<delete>

Creates a route for DELETE I</singular_resource_name/:id.:format>.

    resource("foo",
        delete => sub {
            my ($app, %param) = @_;
            my $foo_id = $param{foo_id};
        }
    )

=item I<idregex>

By default, the I<:id> param matches any char thats not a slash (/), question mark (?) or colon (:). To restrict these rule, either the keywords I<number> (for any integer digits) or I<uuid> (for any valid UUID) may be specified or a regular expression.

    resource("foo",
        idregex => qr{[a-z]+}i
    )

=item I<captvar>

The capture variable will be build by the singular resource name and the suffixed I<_id> string. Any other name can be specified here.

    resource("foo",
        captvar => 'FooID',
        read => sub {
            my ($app, %param) = @_;
            my $id = $param{FooID};
        },
    )

Any captures variables are also stored in the C<captures()> keyword.

=item I<validate>

The value of capture variable can be validated by a single subroutine for all action that have an I<:id> param.

May return an error message or I<undef> in case of success (like L<Validate::Tiny>)

    resource("foo",
        validate => sub {
            my ( $app, $value ) = @_;
            return $value % 2 ? undef : "value $value is odd, not even";
        }
    )

=item I<chain_id>

Whenever an action with an I<:id> param is called, these subroutine will be called first.

    resource("foo",
        chain_id => sub {
            my $id = pop;
            my $obj = get_from_db_somehow($id);
            var(foo_obj => $obj);
        },
        read => sub {
            var('foo_obj')->read();
        },
        update => sub {
            var('foo_obj')->update();
        },
        delete => sub {
            var('foo_obj')->delete();
        },
    )

=item I<chain>

And whenever an action without an I<:id> param is called, these subroutine will called first, too.

    resource("foo",
        chain => sub {
            my $obj = get_from_db_somehow();
            var(foo_table => $obj);
        },
        index => sub {
            var('foo_table')->get_all();
        },
        create => sub {
            var('foo_table')->create();
        },
    )

=item I<single_id>

A prefix handler for defining other resources and routes under the I</singular_resource_name/:id> prefix.

    resource("foo",
        single_id => sub {
            get '/bar' => sub { ... } # matches /foo/xxx/bar
        },
    )

This is also useful for chaining resources together:

    resource("foo",
        single_id => sub {
            resource("bar",
                read => sub {
                    my ($app, %param) = @_;
                    my $foo_id = $param{foo_id};
                    my $bar_id = $param{bar_id};
                }
            );
        },
    );

=item I<single>

A prefix handler for defining other resources and routes under the I</singular_resource_name> prefix.

    resource("foo",
        single => sub {
            get '/bar' => sub { ... } # matches /foo/bar
        },
    )

=item I<plural>

A prefix handler for defining other resources and routes under the I</plural_resource_name> prefix.

    resource("foo(s)",
        plural => sub {
            get '/bar' => sub { ... } # matches /foos/bar
        },
    )

=back

=method publish_apiblueprint ($path)

Define a route path for documentation generated by L<Dancer2::Plugin::CRUD::Documentation>. An format parameter is suffixed, but at the moment only the bare markdown output is supported. So,

    publish_apiblueprint("/doc");

will match I</doc.md>.

After this call the documentation stack will be resetted. This allows to generate multiple documents:

    resource("foo1", ...);
    resource("foo2", ...);
    publish_apiblueprint("/foo_doc");
    
    resource("bar1", ...);
    resource("bar2", ...);
    publish_apiblueprint("/bar_doc");

=method define_serializer ($module, %options)

Define an own serializer which is not defined in L<Dancer2> or this package.

    define_serializer('XML', # searches for Dancer2::Serializer::XML
        extensions => [qw[ xml ]], # format name in URI
        mime_types => [qw[ text/xml ]],
    );
    
    my $serializer = My::Own::Serializer::Module->new;
    ## $serialzier must be consumer of Dancer2::Core::Role::Serializer
    define_serializer($serializer, ...);

Hint: use this keyword before any I<resource> keyword.

=head1 ADDITIONAL FEATURES

=head2 AUTO DISPATCHING

Instead of providing a CodeRef as an action handler, the keyword L<dispatch> enables auto-dispatching. The singular resource name will be camelized and chaining of resources results in sub-sub-classes.

    package Webservice;
    use Dancer2;
    use Dancer2::Plugin::CRUD;
    resource('foo_bar',

        # dispatches to Webservice::FooBar::index_action
        index => 'dispatch',

        single => sub {
            resource('baf_baz',

                # dispatches to Webservice::FooBar::BafBaz::create_action
                create => 'dispatch'

            );
        }
    );

=head2 HANDLE HEAD REQUEST

A HTTP I<HEAD> request behaves like a normal I<GET> request - instead that no body is returned. But all headers should remain the same. In order to improve performance, like with expensive database operations, there is a feature to suppress the generation of the response body when needed. To do that, return a I<CodeRef> in your handler method. With a normal I<GET> request, the CodeRef will be executed, otherwise not.

    resource('foo',
        read => sub {
            # this sub will be run in both HEAD and GET context
            # ALL headers should be set here!
            return $status => sub {
                # this sub will only run when in GET context
                # finally generate and return content
            }
        }
    );

In other contexts where HEAD does not apply, like POST, PUT, DELETE, ..., the CodeRef will be executed everytime. So its recommended to use this feature only with I<index> and I<read> handlers.

=head2 CROSS ORIGIN RESOURCE SHARING

There is a Dancer2 plugin that handles CORS: L<Dancer2::Plugin::CORS>. The I<resource> keyword returns a list of all created L<Dancer2::Core::Route> objects. Here are two examples to use these plugins together

    use Dancer2::Plugin::CRUD;
    use Dancer2::Plugin::CORS;
    my $cors = cors;
    my @routes = resource(...);
    cors->rule(...);
    cors->add(\@routes);

    use Dancer2::Plugin::CRUD;
    use Dancer2::Plugin::CORS;
    my $cors = cors;
    cors->rule(...);
    cors->add([ resource('foo', ...) ]);
    cors->add([ resource('bar', ...) ]);
