#!/usr/bin/perl
use strict;


package DefaultObj;
use Data::Dumper;
use Storable qw'dclone';


sub new {
	my $class = shift;
	my $o = bless ({}, $class);
	$o->setvalue([]);
	$o->{ID} = &::UID();
    Common::setTrait_COLON_to_COLON_($o, 'Common', &::getCommonTrait());
    Common::setTrait_COLON_to_COLON_($o, 'Primitive', $::Proto->{Primitive});
	return $o;
}

 sub setvalue {
              my $s = shift;
              my $val = shift;
              $s->{value} = $val;
          }


package String;
package True;
package False;

package Common;

sub new {
    return bless {};
}

sub setTrait_COLON_to_COLON_ {
  my $o = shift;
  my $name = shift;
  my $trait = shift;
  $o->{traits}->{$name} = $trait;
}

sub getTrait_COLON_ {
  my $o = shift;
  my $name = shift;
  return $o->{traits}->{$name};
}

sub methodNotFound_COLON_reason_COLON_position_COLON_ {
 print " Default native method could not find: '".$_[1]->{value}."' at line ".$_[3]->{value}."'\n";
exit;
}



package Primitive;
use Data::Dumper;
use Storable qw'dclone';


sub new {
	my $class = shift;
	my $o = bless ({}, $class);
	$o->setvalue([]);
	$o->{ID} = &::UID();
    Common::setTrait_COLON_to_COLON_($o, 'Common', &::getCommonTrait());
	return $o;
}



sub clone {
	my $s = shift;
	my $o =  new ref($s);

    foreach my $k ( keys %$s ) {
        $o->{$k} = $s->{$k};
    }

    foreach my $k ( keys %{$s->{traits}} ) {
        $o->{$k}->{traits} = $s->{$k}->{traits};
    }

    foreach my $k ( keys %{$s->{vtable}} ) {
        $o->{$k}->{vtable} = $s->{$k}->{vtable};
    }

	$o->{ID} = &::UID();
	return $o;
}

sub setprop {
    my ($s, $propname, $val) = @_;
    $s->{properties}->{$propname}= $val;
    return $s;
}

sub getprop {
    my ($s, $propname) = @_;
    $s->{properties}->{$propname};
}

sub makeprop_COLON_ {
	my ($s, $propname) = @_;
	my $pname = $propname->value;
	my $propset = $pname."_COLON_";
	$s->{vtable}->{$pname} = sub { return $s->getprop($pname)};
	$s->{vtable}->{$pname."_COLON_"} = sub { return $s->setprop($pname, shift)};
#print Dumper($s->{vtable});
    return $s;
}

sub isObject {
    1;
}
sub equal_COLON_ {
    my $s = shift;
    my $arg = shift;
    if ( $arg->value eq $s->value )
    { return new True; }
    else
    { return new False; }
}
sub notEqual_COLON_ {
	my $s = shift;
	my $arg = shift;
	if ( $arg->value eq $s->value )
	{ return new True; }
	else
	{ return new False; }
}

sub println {
	my $s = shift;
	print $s->value;
	print "\n";
    return new True;
}


sub eprintln {
	my $s = shift;
	warn $s->value;
	warn "\n";
    return new True;
}

sub vprint {
	my $s = shift;
	print $s->value;
    return new True;
}

sub eprint {
	my $s = shift;
	warn $s->value;
    return new True;
}

sub value {
    my $s = shift;
    return $s->{value}
}

sub setvalue {
    my $s = shift;
    my $val = shift;
    $s->{value} = $val;
    return $val;
}
sub prettydump {
	my $s = shift;
    print "***PRETTYDUMP***\n";
    use Data::Dumper;
    $Data::Dumper::Maxdepth=2;
    print Dumper($s);

}

sub asString {
	my $s = shift;
	print "Object has not defined a new, safe, asString!\n";
	return new String("$s->{type}:$s->{subtype}");
}

	sub asNumber {
		my $s = shift;
		return new Number($s->{value});
	}

package Primval;
use base 'Primitive';
sub this_COLON_ {
my $s = shift;
my $str = shift;
print "Started primval \n";
my $i = &::getvalue($str);
$i=~ s/'$//;
print "Evalling '$i'\n";
return eval $i;
}


package Eval;
use base 'Primitive';
sub this_COLON_ {
my $s = shift;
my $str = shift;
print "Started eval \n";
my $i = &::getvalue($str);
my @letters = split //, $i;
&::main(@letters);
}


package While;
use base 'Primitive';
sub test_COLON_do_COLON_ {
	print "Running loop\n";
	my $s = shift;
	my $test = shift;
	my $action = shift;
	my $ret = $test->exec;
	print "Ran test\n";
	use Data::Dumper;
	print Dumper($ret);
	if (ref($ret) =~/True/)
	{$action->exec; $s->test_COLON_do_COLON_($test, $action)}
}

package Object;
use base 'Primitive';

sub dump {
	my $s = shift;
	map { print "$_:".$s->{$_}, "\n" } keys %$s;
}



package Trace;
use base 'DefaultObj';

sub on { $::trace=1; return new Number(1);}
sub off { $::trace=0; return new Number(0);}

package False;
use base 'DefaultObj';

sub ifTrue_COLON_ {return new False;}
sub ifFalse_COLON_ {
	my $s = shift;
	my $arg = shift;
	&::mysend($s, $arg, 'exec');
}  

sub ifTrue_COLON_ifFalse_COLON_ {
	my $s = shift;
	my $arg = shift;
	my $argf = shift;
	&::mysend($s, $argf, 'exec');
}  

package True;
use base 'DefaultObj';

sub ifFalse_COLON_ {return new False;}
sub ifTrue_COLON_ {
	my $s = shift;
	my $arg = shift;
	&::mysend($s, $arg, 'exec');
}  

sub ifTrue_COLON_ifFalse_COLON_ {
	my $s = shift;
	my $arg = shift;
	&::mysend($s, $arg, 'exec');
}  



package AnonBlock;
use base 'Primitive';

sub new {
    my $class = shift;
    my $val = shift;
    my $context = shift;
    my $self  = bless{};
#print "Setting anonval to >".$val."<\n";
    $self->setvalue($val);
    $self->{context}=$context;
    &Common::setTrait_COLON_to_COLON_($self, 'Common', &::getCommonTrait());
    return $self;
}

sub exec {
	my $s = shift;
	&::trace( "Execing anonblock\n");
#$s->{context}->{execnow} = 1;
	my $ret;
	$s->{context}->{execnow} = 1;
	return $s->value->exe($s->{context});
    }


package Web;
use base 'Primitive';

sub get_COLON_ {
    my $s = shift;
    my $arg = shift;
    my $url = $arg->value;
    my $ret =  `wget -O- $url`;
    my $string = new String($ret);
    return $string;
}


package Current;
use base 'DefaultObj';

sub object_COLON_ {
    my $s = shift;
    my $arg = shift;
    $s->{value} = $arg;
    print "Setting Current obj to $arg\n";
    return $arg;
}


package Array;
use base 'DefaultObj';


sub at_COLON_ {
    my $s = shift;
    my $arg = shift;
    return $s->{value}->[$arg->{value}];
}

sub at_COLON_put_COLON_ {
	my $s = shift;
	my $arg = shift;
	my $val = shift;
	return $s->{value}->[$arg->asNumber->{value}] = $val;
}

sub vprint {
    my $s = shift;
    local $,=',';
    print map { $_->{value} } @{$s->{value}};
    }

package Number;
use base 'Primitive';
sub new {
	my $class = shift;
	my $val = shift;
	my $self  = bless{};
	$self->setvalue($val);
    &Common::setTrait_COLON_to_COLON_($self, 'Common', &::getCommonTrait());
	return $self;
}



sub add_COLON_ {
	my $s = shift;
	my $arg = shift;
	my $n = new Number($s->value + $arg->value);
	$n;
}

sub subtract_COLON_ {
	my $s = shift;
	my $arg = shift;
	my $n = new Number($s->value - $arg->value);
	$n;
}

sub multiply_COLON_ {
	my $s = shift;
	my $arg = shift;
	my $n = new Number($s->value * $arg->value);
	$n;
}

sub divide_COLON_ {
	my $s = shift;
	my $arg = shift;
	my $n = new Number($s->value * $arg->value);
	$n;
}

package String;
use Storable qw'dclone';
use base 'Primitive';

sub new {
	my $class = shift;
	my $val = shift;
	my $self  = bless{};
#print "Setting stringval to >".$val."<\n";
	$self->setvalue($val);
    &Common::setTrait_COLON_to_COLON_($self, 'Common', &::getCommonTrait());
	return $self;
}

sub value {
	my $s = shift;
	my $str =  $s->{value} ;
    $str =~ s/'$//;
	return $str;
}

sub concat_COLON_ {
	my $s = shift;
	my $arg = shift;
	$s->setvalue($s->value . $arg->value);
	$s;
}

sub explode {
    my $s = shift;
    my $a = new Array;
    my @letters = map { new String($_) } split //, $s->{value};
    $a->{value} = \@letters;
    return $a;
}
package Io;
use base 'Primitive';

sub readLine {
my $thing = readline(*STDIN);
my $s = new String($thing);
return $s;
}

package For;
use base 'Primitive';

sub all_COLON_do_COLON_ {
    my ( $s, $array, $sub ) = @_;
    foreach my $elem ( @$array ) {
#Call sub here
    }
}

package Set;
use base 'Primitive';
use Data::Dumper;
sub var_COLON_to_COLON_in_COLON_ {
    my ($s, $symbol, $object, $context) = @_;
    $context->{variables}->{$symbol->{value}} = $object;
}

1;
