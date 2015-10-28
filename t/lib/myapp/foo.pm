use strictures 2;

package myapp::foo;

sub index  { [ref(shift)=>0] }
sub create { [ref(shift)=>1] }
sub read   { [ref(shift)=>2] }
sub update { [ref(shift)=>3] }
sub delete { [ref(shift)=>4] }
sub patch  { [ref(shift)=>5] }

1;
