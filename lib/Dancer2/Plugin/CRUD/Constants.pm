use strictures 1;

package Dancer2::Plugin::CRUD::Constants;

use Exporter qw(import);

our @EXPORT_OK = qw(%ext_to_fmt %type_to_fmt %trigger_to_method %RE);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

our %ext_to_fmt = (
    jsn  => 'JSON',
    json => 'JSON',
    yml  => 'YAML',
    yaml => 'YAML',
    dmp  => 'Dumper',
    dump => 'Dumper',
);

our %type_to_fmt = (
    'text/x-yaml'        => 'YAML',
    'text/yaml'          => 'YAML',
    'text/x-data-dumper' => 'Dumper',
    'text/x-perl'        => 'Dumper',
    'text/x-json'        => 'JSON',
    'text/json'          => 'JSON',
    'application/json'   => 'JSON',
);

our %trigger_to_method = (
    index  => 'get',
    read   => 'get',
    create => 'post',
    update => 'put',
    patch  => 'patch',
    delete => 'delete',
    head   => 'head',
);

our %RE = (
    uuid => qr{
		[0-9a-f]{8}
		-
		[0-9a-f]{4}
		-
		[0-9a-f]{4}
		-
		[0-9a-f]{4}
		-
		[0-9a-f]{12}
	}xsi,
    number => qr{\d+},
);

1;
