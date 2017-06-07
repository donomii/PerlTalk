use strict;
use SchemeParser;
#use MyLang;

my $ev = new Environment;
$ev->rawset("set", new NativeCall(sub {print Dumper(@_); my $env = shift; $env->set(@_)}));
$ev->delayargs(new String("set"));
$ev->rawset("lambda", new NativeCall(sub {  return new Closure(@_);}));
$ev->delayargs(new String("lambda"));
$ev->rawset("declare", new NativeCall(sub {  my $env = shift; $env->declare($_) foreach @_}));
$ev->delayargs(new String("declare"));
$ev->rawset("if", new NativeCall(sub { my $env = shift; print "Testing: ".$_[0]->evaluate($env)->value."\n"; if ( $_[0]->value ) { return $_[1]->activate()} else { return $_[2]->activate()}}));
$ev->rawset("+", new NativeCall(sub { shift; my $accum = 0; foreach ( @_ ) { $accum+=$_->{content}}; return new Number($accum);}));
$ev->rawset("println", new NativeCall(sub { shift; my $str = join("",  map {  $_->{content} } @_) ; new String($str);} ));
$ev->rawset("let", 
  new NativeCall(sub { my ($env, $bindings, $body) = @_; my $newenv = $env->extend; 
  foreach my $assgn ( @{$bindings->value} ) {
      my ($sym, $val) = @{$assgn->value};
      $newenv -> declare( $sym );
      $newenv -> set ( $sym, $val);
  }
      $body->evaluate($newenv)
      } ));
  $ev->delayargs( new String("let"));
#SchemeParser::run( "declare a b c ; set a 1 ; set a 2 ; set b 2 ; set c ( + a b ) ; if [ c ] [ println 'c is ' ; println c ] [ println c ] ");
SchemeParser::run( "( + 1 1 ) ", $ev);
SchemeParser::run( "(let ( ( a 1 ) ( b 3 ) ) ( + a b ) ) ", $ev);
#MyLang::run( "( + 1 1 ) ", $ev);

sub interactive {
    while (1) {
    my $inp = <>;
    chomp $inp;
    my $ret = SchemeParser::run($inp, $ev);
    #my $ret = MyLang::run($inp, $ev);
    print $ret->dump, "|\n";
}
}

interactive();
    

package Environment;
use strict;
use warnings;
use Data::Dumper;
sub new { return bless {}};
sub rawset {
    my ($self, $sym, $val) = @_;
    $self->{vars}->{$sym} = $val;
}
sub extend {
    my $self = shift;
    my $new = new Environment();
    print "Extending environment\n";
    $new->{parent} = $self;
    return $new;
}
sub declare {
    my $self = shift;
    my $sym = shift;
    $self->{vars}->{$sym->{content}} = undef;
}

sub delayargs {
    my ($self, $sym, $val) = @_;
    $self->{delayed}->{$sym->{content}} = 1;
}
sub delayed {
    my $self = shift;
    my $sym = shift;
    my $ret = $self->{delayed}->{$sym->{content}} ;
    if($self->{parent}) {
        $ret ||= $self->{parent}->delayed($sym);
    }
    return $ret;
}

sub set {
    my ($self, $sym, $rawval) = @_;
    my $val = $rawval->evaluate($self);
    $self->{vars}->{$sym->{content}} = $val;
    print( "Setting: ".$sym->{content} , $val->value, "\n");
    
    return $val;
}
sub lookUp{
    my $self = shift;
    my $sym = shift;
    print "Calling lookUp on $sym->{content}\n";
    #print "Env:".Dumper($env);
    if ( exists($self->{vars}->{$sym->{content}})) {
        print "Returning $self->{vars}->{$sym->{content}}\n"; 
        return $self->{vars}->{$sym->{content}}
    }
    if ($self->{parent}) {
        return $self->{parent}->lookUp($sym);
    }
    print "Variable not found: $sym->{content}\n";
    die;
}
package NativeCall;
sub activate { my $self = shift;  $self->value->($self->{env}, @_) }  #XXXFixme pass env?
package Number;
sub evaluate { return $_[0]; }
sub activate { return $_[0]; }
package Symbol;
sub evaluate { return $_[1]->lookUp($_[0])||$_[0]; }
package String;
sub evaluate { return $_[0]; }
package Expression;
sub activate { my $self = shift;  $self->value->(@_); } #XXX Fixme pass env?
sub evaluate { my $self = shift; my $env = shift;
    my @rawargs = @{$self->value};
    print "Evaluating ".$self->dump." with env: ".Dumper($env)."\n";
    my $rawobj = shift @rawargs;
    my $obj = $rawobj->evaluate($env) ; my @args;
    if($env->delayed($rawobj)) {
        @args = @rawargs;
        print "Not evaluating args\n";
    } else {
        use Data::Dumper;
        print "Evaluating args ".join( " ", map { print Dumper($_); $_->value } @rawargs)."\n";
        @args = map {$_->evaluate($env)} @rawargs;
    }
    print "Calling ".$obj->value." with args:",join(" ",  map { $_->value } @args), "\n";
    $obj->{env} = $env;
    my $ret = $obj->activate(@args);
    $obj->{env} = undef;
    #print "Returning $ret \n";
    return $ret; }
package Sequence;
package Lambda;
use Data::Dumper;
sub evaluate { my $self=shift;my $env = shift; $self->{env} = $env->extend;return $self }
sub activate { my $self = shift; my $ret;  map { $ret = $_->evaluate($self->{env})} @{$self->value}; return $ret; }
package Closure;
sub new {
    my ($class, $env, $args, $body) = @_;

    my $h = { args => $args, body => $body, bound_env => $env};
    print "Created new closure with env:".Dumper($env)."\n";
    return bless $h, $class;
}
sub evaluate { return $_[0] }
use Data::Dumper;
sub activate {
    print Dumper(\@_);
    my ($self, @args) = @_;
    print "Activating closure with args: ", @args, " and env ", Dumper($self->{env}), "\n";
    use Data::Dumper;
    my $newenv = $self->{bound_env}->extend;
    foreach my $argname ( @{$self->{args}->value}) { $newenv->declare($argname) }
    foreach my $ind ( 0..(scalar(@{$self->{args}->value})-1) ) {
        my $argname = $self->{args}->value->[$ind];
        my $val = $args[$ind];
        print "Binding ".$argname->value.", $val\n";
        $newenv->set($argname,$val);
    }
    return $self->{body}->evaluate($newenv);
}
sub value { "Closure" }

