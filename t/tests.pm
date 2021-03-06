use strictures 1;
use Test::Most qw(!pass);
use Plack::Test;
use HTTP::Request::Common ();
use Class::Load qw(try_load_class);

sub soft_require {
    foreach my $class (@_) {
        unless ( try_load_class($class) ) {
            if ( $ENV{AUTHOR_TESTING} ) {
                die "module $class required for this test";
            }
            else {
                plan skip_all => "module $class required for this test";
                exit;
            }
        }
    }
}

sub islc {
    @_ = map { defined($_) ? lc($_) : undef } @_;
    goto &is;
}

sub isntlc {
    @_ = map { defined($_) ? lc($_) : undef } @_;
    goto &isnt;
}

sub header {
    my ( $R, $V ) = @_;
    return $R->header( lc($V) ) || undef;
}

sub boot {
    my $class = shift;
    return Plack::Test->create( $class->to_app );
}

sub dotest {
    my ( $name, $plan, $code ) = @_;
    return subtest $name => sub {
        plan tests => $plan if $plan;
        $code->();
    };
}

sub request {
    my $PT = shift;
    return $PT->request( HTTP::Request::Common::_simple_req(@_) );
}

sub form_request {
    my $PT = shift;
    return $PT->request( HTTP::Request::Common::request_type_with_data(@_) );
}

sub OPTIONS {
    return HTTP::Request::Common::_simple_req( OPTIONS => @_ );
}

1;
