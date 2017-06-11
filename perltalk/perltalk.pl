#!/usr/bin/perl
use Data::Dumper;
$Data::Dumper::Maxdepth=3;
use strict;
use warnings;
use diagnostics;
use Objects;
use CellParser;
$::trace = 1;

my $sourcefile = shift;
$sourcefile || die "Please specify smalltalk file to load\n";
print "Loading $sourcefile\n";
our @data = `cat $sourcefile`;


sub trace {
	if ($::trace) 
    { print ">";print @_;}
    else { 1}
    }

{ my $uid = 1;
	sub UID { return $uid++;}
}

sub add_proto {
	my $name = shift;
	$::Proto->{$name} = new $name;
    #print Dumper($::Proto->{$name});
}
sub hashdump {
	my $s = shift;
	foreach my $k ( keys %{$s} )
	{ print "$k: ".$s->{$k}."\n";}
	print "--\n";
}

sub getvalue {
  my $o = shift;
  #$Data::Dumper::Depth=1;
  #print Dumper $o;
  my $val = $o->{value};
  return $val if $val;
  if ($o->{realobject}) { return $o->{realobject}->{value};}
  return $o->{value};
}
sub mysend {
	my $from = shift;
	my $obj = shift;
	my $meth = shift;
	$meth =~ s/:/_COLON_/g;
	&::trace( "Starting method $meth with args: ", @_, "\n");
	&::trace( "Vtable: ", Dumper($obj->{vtable}) );
    my $ret;
    my $method = $obj->{vtable}->{$meth} || $obj->{vtable}->{$meth};
    if ( $method ) {
        &::trace("Found user function at $method\n");
        eval { $ret = $method->(@_);} ;
    } else {
        &::trace("Attempting native call for $meth on $obj\n");
        eval { $ret =$obj->$meth(@_) }; # || default fail object 
        if ($ret) {&::trace("Native call returned $ret\n");}
        $@ && print $@;
        &::trace("Native call returned $ret\n");

    }
    return $ret if $ret;
    #Recursively call the traits to find a method to run
      &::trace( "Traits: ", Dumper $obj);
    foreach my $key ( keys%{$obj->{traits}} ) {
      &::trace( "Passing call to trait $key", "\n");
      my $trait = $obj->{traits}->{$key};
      if ( $trait ) { $ret = mysend($from, $trait, $meth, @_); }
      return $ret if $ret;
    }
	&::trace( "Finishing method $meth with args: ", @_, "\n");
	#We couldn't find the right method anywhere, so it's time to call methodnotfound
	unless ( $meth eq 'methodNotFound_COLON_reason_COLON_position_COLON_') {
 		$ret = mysend($obj, $obj, 'methodNotFound_COLON_reason_COLON_position_COLON_', new String($meth), new String("Method not found"), new String($from->{pos}));
		return $ret if $ret;
        exit;
	}

	return $ret;
}
$::Proto = {};
add_proto($_) foreach ( qw'Common Primitive String Array Number Current Web AnonBlock True False While Object Trace Eval Primval Io For Set');
$::Proto->{Current}->{value} = $::Proto->{Common};
#print Dumper ($::Proto);
sub getCommonTrait {
    return $::Proto->{Common};
}
print @data;
my $data = join("", @data);
my @letters = split(//, $data);
main(@letters);
sub main {
my @letters = @_;
my $c = new Neo;
$c->become( "START");
$c->input(\@letters);
my $last = $c->eatArray();
$last->become( "END");
$c->annotate(0,1);
#print Dumper $last;
&::trace(print "First pass done, file read\n");
foreach (1..15) { $c->run; $last->runback; }
&::trace(print "second pass done\n");
$c->dump;;
$c = $c->evolve;
#print Dumper $c;
$c=$c->findfirst;
foreach (1..20) { $c->run;$c->dump; print "\n"; }
&::trace(print "third pass done\n");

#$c->dump;
my $nodes = $c->makenodes;
$nodes = $nodes->findfirst;
foreach (1..15) {$nodes->run; $nodes->dump;print "\n";}
&::trace(print "fourth pass done\n");
$nodes->dump();
#$nodes->emitXML();
$nodes->exe({ variables => $::Proto});
#print Dumper($nodes);
}
print "Finished program\n";
exit;

package LinkList;

{
	my $num = 0;
	sub sequence { return $num++;}
}

sub hashdump {
	my $s = shift;
	foreach my $k ( keys %{$s} )
	{ print "$k: ".$s->{$k}."\n";}
	print "--\n";
}
sub pheno {
	my ($s) = @_;
	return $s->{pheno}
}

sub become {
	my ($s, $new) = @_;
	$s->{subtype} ||= $s->{pheno};
	$s->{pheno} = $new;
}

sub is {
	my ($s, $q) = @_;
	if ($q) { if ($q eq $s->pheno) {return 1} else {return 0}}
	return $s->pheno;
}

sub isprev {
	my ($s, $q) = @_;
	return $s->prev->is($q);
}
sub isnext {
	my ($s, $q) = @_;
	return $s->next->is($q);
}

sub next {
	my ($s, $val) = @_;
	if ($val) { $s->{next} = $val;}
    if ($s->{next} == $s) { return undef}
	return $s->{next};
}
sub prev {
	my ($s, $val) = @_;
	if ($val) { $s->{prev} = $val;}
	return $s->{prev};
}
sub findfirst {
	my ($s) = @_;
	if ($s->prev){
		return $s->prev->findfirst;}
	else
	{return $s}
}

sub run{
	my ($s) = @_;
	$s->doStuff();
	return unless $s->next();
	$s->next()->run();
}
sub annotate{
	my ($s, $pos, $line) = @_;
	$s->{pos} = "$line:$pos";
	if ($s->{content} =~ "\n" ) { $line++;$pos=-1;}
	return unless $s->next();
	$s->next()->annotate($pos+1, $line);
}
sub emit{
	my ($s) = @_;
	$s->emitParrot();
	return unless $s->next();
	$s->next()->emit();
}
sub runback{
	my ($s) = @_;
	$s->doStuff();
	return unless $s->prev();
	$s->prev()->runback();
}

sub suicide {
	my $s = shift;
	$s->prev->next($s->next);
	$s->next->prev($s->prev);
}

sub brule {
	my ($s, $pattern, $effect) = @_;
	return unless $s->prev();
	return unless $s->next();
	if (($s->is eq $pattern->[1]) || ($pattern->[1] eq "ANY")) {
		if (($s->prev->is eq $pattern->[0]) || ($pattern->[0] eq "ANY")) {
			if(($s->next->is eq $pattern->[2]) || ($pattern->[2] eq "ANY")) {
				$s->become($effect);}}}}
				sub rule {
					my ($s, $pattern, $effect) = @_;
					return unless $s->prev();
					return unless $s->next();
					if (($s->is eq $pattern->[1]) || ($pattern->[1] eq "ANY")) {
						if (($s->prev->is eq $pattern->[0]) || ($pattern->[0] eq "ANY")) {
							if(($s->next->is eq $pattern->[2]) || ($pattern->[2] eq "ANY")) {
								$effect->();
							}}}}


package Node;
use base "LinkList";
use Data::Dumper;

sub new {
	my $o = bless {};
	return $o;
}


sub dump {
	my ($s) = @_;
#print Dumper $s;
	print "[".$s->{pheno}."(".$s->{origin}->{content}.$s->{subtype}. ")] ";
	if ($s->next){$s->next->dump();}
}


sub addarg {
	my ($s, $arg) = @_;
    &::trace("Adding $arg->{content} to $s->{content}\n");
	$s->{arglist} ||= [];
	push @{$s->{arglist}}, $arg;
}


sub engulfnext {
	my ($s) = @_;
    my $target = $s->next;
	$s->next($s->next->next());
	$s->next->prev($s);
    $target->{next} = undef;
    $target->{prev} = undef;
}


sub engulfprev {
	my $s = shift;
	$s->prev($s->prev->prev());
	$s->prev->next($s);
}

sub doStuff{
	my $s = shift;
	$s->rule( ["VARIABLETOBEASSIGNED", "ASSIGNMENT", "EXPRESSION"],
			sub {$s->{subtype} = $s->is;$s->become("STATEMENT");
			$s->{value} = $s->next;$s->engulfnext; $s->{target} = $s->prev;$s->engulfprev;});
	$s->rule( [ "ANY", "ARGNAME", "EXPRESSION" ], sub {$s->become("ARG");$s->{value} = $s->next;$s->engulfnext;} );
	if(($s->is eq "RETURN") && ($s->next->is eq "EXPRESSION"))
        {$s->{subtype} = $s->is;$s->become("STATEMENT");$s->{value} = $s->next;$s->engulfnext;}
	$s->brule( [ "ANY", "(",     "ANY" ] => "STARTEXPRESSION");
	$s->brule( [ "ANY", ")",     "ANY" ] => "ENDEXPRESSION");
	$s->brule( [ "ANY", "STARTEXPRESSION", "ENDEXPRESSION"    ] => "EXPRESSION");
	$s->rule( [ "EXPRESSION", "ENDEXPRESSION", "ANY"     ] => sub{$s->suicide;});
	$s->rule( [ "ANY", "STARTEXPRESSION", "ANY"     ] => sub{$s->engulfnext;});

	$s->brule( [ "ARGNAME", "VARIABLENAME",     "TERMINATOR" ] => "EXPRESSION");
	$s->brule( [ "RETURN", "VARIABLENAME",     "TERMINATOR" ] => "EXPRESSION");
	$s->brule( [ "ASSIGNMENT", "VARIABLENAME",     "TERMINATOR" ] => "EXPRESSION");
	$s->brule( [ "ARGNAME", "VARIABLENAME",     "ENDANON" ]    => "EXPRESSION");
	$s->brule( [ "STARTANON", "VARIABLENAME",     "ENDANON" ]    => "EXPRESSION");
	$s->brule( [ "ARGNAME", "VARIABLENAME",     "ARGNAME" ],   => "EXPRESSION");
	$s->brule( [ "ARGNAME", "VARIABLENAME",     "METHODSIG" ],   => "EXPRESSION");
	$s->brule( [ "ARGNAME", "PROTO-EXPRESSION", "TERMINATOR" ] => "EXPRESSION");
	$s->brule( [ "RETURN", "PROTO-EXPRESSION", "TERMINATOR" ] => "EXPRESSION");
	$s->brule( [ "ARGNAME", "PROTO-EXPRESSION", "ENDANON" ] => "EXPRESSION");
	$s->brule( [ "ARGNAME", "PROTO-EXPRESSION", "ARGNAME" ]    => "EXPRESSION");
	$s->brule ( [ "ARGNAME",     "PROTO-EXPRESSION", "ARG" ], "EXPRESSION");
	#$s->rule ( [ "ANY",     "EXPRESSION", "ARG" ], sub  { $s->addarg($s->next);$s->engulfnext;});
	$s->rule ( [ "ARG",     "METHODSIG", "ANY" ], sub  { $s->addarg($s->prev);$s->engulfprev;});
	$s->rule ( [ "VARIABLENAME",     "METHODSIG", "ANY" ], sub  { $s->addarg($s->prev);$s->engulfprev;});
	$s->brule( [ "ANY",     "OBJECT",           "ANY" ]        => "PROTO-EXPRESSION");
	$s->brule( [ "ASSIGNMENT", "PROTO-EXPRESSION", "TERMINATOR" ] => "EXPRESSION");
	$s->brule( [ "TERMINATOR", "PROTO-EXPRESSION", "TERMINATOR" ] => "EXPRESSION");
	#$s->brule( [ "TERMINATOR", "EXPRESSION",       "TERMINATOR" ] => "STATEMENT");
	#$s->brule( [ "TERMINATOR", "EXPRESSION",       "END" ] => "STATEMENT");
	#$s->brule( [ "START", "EXPRESSION",       "TERMINATOR" ] => "STATEMENT");
	$s->brule( [ "STARTANON",  "PROTO-EXPRESSION", "ENDANON" ]    => "EXPRESSION");
    $s->rule( ["ANY", "IDENTIFIER", "IDENTIFIER"],
	sub { $s->{subtype} = "UNARYCALL"; $s->addarg($s->next);  $s->{method} = $s->next; $s->engulfnext; $s->become("UNARYCALL")});
    $s->rule( ["ANY", "ANY", "NOARGSCALL"],
	sub { $s->{subtype} = "UNARYCALL"; $s->addarg($s->next);  $s->{method} = $s->next; $s->engulfnext; $s->become("UNARYCALL")});
	if($s->is eq "NUMBER") { $s->{object} = $s->{content}; $s->{subtype} = $s->is; $s->become("OBJECT")}
	if($s->is eq "STRING") { $s->{object} = $s->{content}; $s->{subtype} = $s->is; $s->become("OBJECT")}
	$s->brule ( [ "TERMINATOR", "VARIABLENAME",  "ARG" ], "MULTIARGCALL");
	$s->rule ( [ "ANY",     "MULTIARGCALL", "ARG" ], sub  { $s->addarg($s->next);$s->engulfnext;});
	$s->rule ( [ "ANONPARAMNAME", "ANONPARAMLIST", "ANY" ], sub  { shift @{$s->{paramlist}}, $s->prev;$s->engulfprev;});
	if (($s->is eq "STARTANON") && ($s->next->is eq "ANONPARAMLIST")) { $s->{paramlist} = $s->next;$s->engulfnext;}
	$s->rule ( [ "STARTANON", "EXPRESSION", "ANY" ], sub { $s->prev->addarg($s);$s->prev->engulfnext;});
	$s->rule ( [ "STARTANON", "STATEMENT",  "ANY" ], sub { $s->prev->addarg($s);$s->prev->engulfnext;});
	$s->rule ( [ "ANY", "STARTANON", "ENDANON" ],    sub { $s->{subtype} = "ANON";$s->engulfnext;$s->become("EXPRESSION");});
	$s->rule ( [ "STARTANON", "TERMINATOR", "ANY" ],    sub { $s->suicide;});
}


sub calcMethodCallSig {
	my $s = shift;
    #print Dumper $s->{arglist};
	my $sig = "";
	foreach my $arg ( @{$s->{arglist}})
	{$sig .= $arg->{origin}->{content}}
	return $sig;
} 

sub calcMethodSig {
	my $s = shift;
	my $sig = "";
	foreach my $arg ( @{$s->{arglist}})
	{$sig .= $arg->{origin}->{content}}
	return $sig;
} 

sub exeMethodArgs {
	my $s = shift;
	my $context = shift;
	my @args=();
	foreach my $arg ( @{$s->{arglist}})
	{
#$arg->hashdump;
		my $val = $arg->{value}->exe($context);
		unless ($val||$val->{PROXY}) { die "Method arg is not an object:", Dumper $val;}
		push @args,  $val;
	}
	return \@args;
} 

sub emitParrotMethodArgs {
	my $s = shift;
	my $sig = "";
	my @arglist = ();
	foreach my $arg ( @{$s->{arglist}})
	{ 
		#print "# ". $arg->{origin}->{content} . "\n";
		$arg->{value}->emitParrot;
		push @arglist, "\$P".($s->sequence-1);
#print "Store \$P",$s->sequence-1," in ".$arg->{origin}->{content}, "\n";
	}
	return @arglist;
} 

sub mysend {
	&::mysend(@_);
}

sub Runloop { 
	my $s = shift;
	my $name = shift;
	my $context = shift;
#print "Looking up ".Dumper($name)."\n";
	if ($name->is eq "STRING")
	{ 
		my $o = new String($name->{content});
		$o->{pos} = $s->{pos};
		return $o;
	}
	if ($name->is eq "NUMBER")
	{ 
		#&::trace("Looking up Number ".$name->{content}."\n");
		my $o = new Number( $name->{content});
		$o->{pos} = $s->{pos};
		return $o;
	}
	if ($name->is eq "VARIABLENAME"||$name->is eq "IDENTIFIER")
	{ 
		my $n = $name->{content};
        return lookUp($n, $context);
		#&::trace("Looking up $n\n");
		my $obj =  $context->{variables}->{$n};
		unless ($obj) 
		{ if ($context->{parentContext}) 
			{#print  "Failed to look up ".$name->{content}." in ".Dumper($context)."\n";
				$obj = $s->Runloop($name, $context->{parentContext});}}
				unless ($obj)
				{ $obj = $context->{$name->{content}}; }
				$obj || die "Failed to look up >".$name->{content}."< in context ".Dumper($context)."\n";
				#&::trace("$n is $obj\n");
				return $obj;

	}

	die "Failed to look up ".$name->{content}."\n";
}

sub walk_args {
    #print "Walking args\n";
	my ($s, $context) = @_;
    my $param = pop @{$context->{args}};
    #print "Pheno: ".$s->{pheno}."\n";
    if ($s->{pheno} eq 'ARG') {
        #print "Dumping args\n";
        #print "Argname: ".$s->{content}."\n";
        #print "Value: ". $s->{value}."\n";
        #print "Param: ". $param."\n";
        #print "Setting ".$s->{value}->{content}." to ".$param."\n";
        $context->{variables}->{$s->{value}->{content}} = $param;
        #print Dumper($context);
        if ( $s->{prev} && $s->{prev}->{pheno} eq 'ARG') {
            walk_args($s->{prev}, $context);
        }
    }
}
sub bind_args {
#need to walk back through the arg list ad bind each param
	my ($s, $context) = @_;
    walk_args(@{$s->{arglist}}[0], $context);
	#my $i = 0;
    #print "Arglist ".join(',',@{$context->{args}})."\n";
 #print Dumper(@{$context->{args}});
	#foreach my $arg ( @{$context->{args}}) {
		#my $target_a = @{$s->{arglist}}[$i];
		#my $target = $target_a->{value}->{content};
 #&::trace("Setting arg name: $target to $arg\n");
		#$context->{variables}->{$target} = $arg;
	#}
}

sub lookUp {
    my ( $symbol, $context ) = @_;
    #print "Looking up variable $symbol\n";
    if ($symbol eq 'thisContext' ) { return $context }
    my $val = $context->{variables}->{$symbol};
    return $val if $val;
    if ( $context->{previous_context} ) {
        return lookUp($symbol, $context->{previous});
    }
    die "Failed to lookup variable name $symbol\n";
}

sub exe {
	my $s = shift;
	my $context = shift;
nextCell:
	my ($line, $pos) = split /:/, $s->{pos};
	&::trace( "\nExeing ".$s->is."(".$s->{subtype}.")".$s->{content}." at ". $s->{pos}."\n");
	&::trace ($s->{pos}.">".$::data[$line-1],"\n");
#print Dumper($context);
#$s->hashdump;
	if ($s->is eq "TERMINATOR" || $s->is eq "START") {
		if( $s->next) { 
			return $s->next->exe($context);
			#if ($s->next->next) {
				#$s->next->next->exe($context);
			#}
		}
	}
	if ($s->is eq "END") {exit;}
	if ($s->is eq "DECLAREVARIABLE") {
#print "Declaring variable ".$s->{origin}->{content}."\n";
	}
	if ($s->is eq "METHODSIG") {
#print "In method ".$s->calcMethodSig."\n";
		if ($context->{execnow}) { 
			$context->{execnow} = 0;
#print "Running method\n";
			$context->{args} = \@_;
			$s->bind_args($context);
			return $s->next->exe($context);}
		else {
			my $meth = $s->calcMethodSig;
			my $finalc = 0;
			if ( $meth =~ /:$/ ) { $finalc=1;}
			my @meth = split /:/, $meth;
			$meth = join("_COLON_", reverse(@meth));
			if ($finalc) { $meth .= "_COLON_" }
			#$meth=~s/:/_COLON_/g;
			&::trace( "Registering ".$meth."\n");
			&::trace( "{Current}->{value}->{vtable}->{$meth} \n");
			&::trace($::Proto."\n");
			&::trace(Dumper($::Proto->{Current}));
			&::trace(Dumper($::Proto->{Current}->{value}));
			&::trace($::Proto->{Current}->{value}->{vtable}."\n");
			$::Proto->{Current}->{value}->{vtable}->{$meth} = sub {$s->exe({execnow=>1, parentContext=>$context},@_);};
print "Skipping...\n";
			$s->skipToReturn($context);return;
		}
	}
		if($s->is eq "MULTIARGCALL") {
			my $obj = $s->Runloop($s->{origin}, $context);
			#&::trace($s->{pos}.">".&::getvalue($obj)." ". $s->{method}->{content} .".\n");
			$s->mysend($obj, $s->calcMethodCallSig, @{$s->exeMethodArgs($context)});
            $s->next->exe($context);
		}
        if ($s->{subtype} eq "UNARYCALL") { 
			my $obj =  $s->Runloop($s->{origin}, $context);
			&::trace($s->{pos}.">".&::getvalue($obj)." ". $s->{method}->{content} .".\n");
			$s->mysend($obj, $s->{method}->{content});
            $s->next->exe($context);
		}

	if ($s->is eq "EXPRESSION") {
		if ($s->{subtype} eq "ANON") {
			if ($context->{execnow}) { 
				$context->{execnow} = 0;
#print "Running anonblock\n";
#$s->{value}->hashdump;
				my $ret;
				my $arglist = $s->{arglist};
				my @arglist = @{$arglist};
				$arglist[-1]->{pheno} = "EXPRESSION";
				$ret = $arglist[0]->exe($context);
#foreach my $expr ( @arglist )
#{
#print "In anonblock, execing: ".$expr->is."\n";
#$ret  = $expr->exe($context); }
#print "Finished anon block, returned $ret\n";
				return $ret;
			}
			else {
#print "Creating anonblock\n";
				my $block = new AnonBlock($s, $context);
				$block->{pos} = $s->{pos};
				return $block;
			}
		}
		if ($s->{subtype} eq "ASSIGNMENT") { 
#print "Calculating value:\n";
			&::trace($s->{pos}.">". $s->{target}->{content}. " = ");
			my $val = $s->{value}->exe($context);
#print "Assigning to ".$s->{target}->{content}."\n";
			$context->{variables}->{$s->{target}->{content}} = $val;
			#&::trace(&::hashdump($s->{target})." = ". $val ."\n");
			return $val;
		}

		if ($s->{subtype} eq "VARIABLENAME") { 
			return $s->Runloop($s->{origin}, $context)
		}
        if ($s->{subtype} eq "NUMBER") { 
			&::trace("Creating new number\n");
			my $o = new Number( $s->{content});
			$o->{pos} = $s->{pos};
            &::trace("Number created");
			return $o;
            &::trace("You should never see this");
		}
		if ($s->{subtype} eq "STRING") { 
#print "Creating new string\n";
			my $o = new String( $s->{content});
			$o->{pos} = $s->{pos};
			return $o;
		}
	}
	if ($s->is eq "STATEMENT") { 
		if($s->{subtype} eq "RETURN") {
            print "Starting return for ".$s->{value}."\n";
            print "Starting return for ".Dumper($s)."\n";
            print "Starting return for ".Dumper($s->{value})."\n";
			my $ret = $s->{value}->exe($context);
            print "Returning from return: ".Dumper($ret)."\n";
			return $ret;
		}
		if ($s->{subtype} eq "ASSIGNMENT") { 
#print "Calculating value:\n";
			&::trace($s->{pos}.">". $s->{target}->{content}. " = ");
			my $val = $s->{value}->exe($context);
#print "Assigning to ".$s->{target}->{content}."\n";
			$context->{variables}->{$s->{target}->{content}} = $val;
			#&::trace(&::hashdump($s->{target})." = ". $val ."\n");


		}
	}

    #while($s->next() && $s->next->{content} ne "^"){
        #&::trace( "Moving from ".$s->{content} ." to ".$s->next->{content}."\n");
        #if( $s->next()) {
            #$s->next->exe($context);
            #$s = $s->next;
            #goto nextCell;
        #}
    #}
	#print "Fell off end of run loop(".$s->next().")\n";
}

sub skipToReturn {
	my $s = shift;
	my $context = shift;
    &::trace("Skipping to return\n");
	if (defined($s->{subtype}) && ($s->{subtype} eq "RETURN")) { $s->next->next->exe($context) }
	else
	{if( $s->next) { $s->next->skipToReturn($context);}}
}

sub emitXML {
    my $s = shift;
    if ($s->is eq "START") { print "<Program>\n";$s->next->emitXML;print "</Program>\n";return;}
    if (($s->is eq "STATEMENT") || ($s->is eq "EXPRESSION")) {
        print "<".$s->is.">";
        if ($s->{subtype} eq "NUMBER") { print "<Number>", $s->{origin}->{content}, "</Number>";}
        if ($s->{subtype} eq "STRING") { print "<String>", $s->{origin}->{content}, "</String>";}
        if($s->{subtype} eq "UNARYCALL") {
            print "<unaryCall><object>".$s->{content}."</object>"."<method>".$s->{method}->{origin}->{content}."</method></unaryCall>\n";
        }

        if($s->{subtype} eq "RETURN"){
            print "return\n"; 
        }
        if($s->{subtype} eq "ASSIGNMENT") {
#$s->{value}->emitParrot."\n";
            print "<bind binding=\"".$s->{target}->{content}."\" > <value>";
            $s->{value}->emitXML;
            print "</value></bind>\n"; 
        }
        if($s->{subtype} eq "MULTIARGCALL") {
            my @arglist =();# $s->emitParrotMethodArgs;
            print "\$P".$s->sequence." = Runloop('".$s->{object}->{origin}."')\n";
            my $lastseq = $s->sequence-1;
            print "<multiArgCall object=\"".$s->{content}."\" >\n";
            foreach my $arg (@arglist) {
                print "<argument>$arg</argument>\n";
            }
            print "</multiArgCall>\n";

        }
        print "</".$s->is.">\n";


    }
    $s->next->emitXML();
}


sub emitParrot {
	my $s = shift;
#print "Processing: ", $s->hashdump, "\n";
	if ($s->is eq "START") { print "#Entering routine...\n";}
	if ($s->is eq "EXPRESSION") {
#print "Calculate ".$s->{subtype}." and store in \$P".$s->sequence."\n";
		if ($s->{subtype} eq "NUMBER") { print "\$P", $s->sequence, " = ", $s->{origin}->{content}, "\n";}
		if ($s->{subtype} eq "STRING") { print "\$P", $s->sequence, " = ", $s->{origin}->{content}, "\n";}
		if($s->{subtype} eq "MULTIARGCALL") {
			my @arglist = $s->emitParrotMethodArgs;
			print "\$P".$s->sequence." = Runloop('".$s->{object}->{origin}."')\n";
			my $lastseq = $s->sequence-1;
			print "\$P".$s->sequence." = \$P".($lastseq).".'".$s->calcMethodCallSig. "'(".join(",", @arglist). ")\n";
		}
		if($s->{subtype} eq "UNARYCALL") {
			print "\$P".$s->sequence." = Runloop('".$s->{origin}."')\n";
			my $lastseq = $s->sequence-1;
			print "\$P".$s->sequence." = \$P".($lastseq).".'".$s->{method}->{origin}->{content}."'()\n";}
			if($s->{subtype} eq "VARIABLENAME"){
				print "#VARIBALENAME ".$s->{origin}->{content}."\n";
				print "\$P".$s->sequence." = Runloop('".$s->{origin}."')\n";
			}
	}
	if ($s->is eq "STATEMENT") {
		print "#Start ".$s->{subtype}." statement\n";
		if($s->{subtype} eq "UNARYCALL") {
			print "\$P".$s->sequence." = Runloop('".$s->{origin}."')\n";
			print "\$P".($s->sequence-1).".'".$s->{method}->{origin}->{content}."'()\n";}
			if($s->{subtype} eq "RETURN"){
				#$s->{value}->emitParrot."\n";
				print ".return(\$P".($s->sequence-1).")\n"; 
			}
			if($s->{subtype} eq "ASSIGNMENT") {
				#$s->{value}->emitParrot."\n";
				print "store('".$s->{target}->{origin}->{content}."', \$P".($s->sequence-1).")\n"; 
			}
			if($s->{subtype} eq "MULTIARGCALL") {
				my @arglist = $s->emitParrotMethodArgs;
				print "\$P".$s->sequence." = Runloop('".$s->{object}->{origin}."')\n";
				my $lastseq = $s->sequence-1;
				print "\$P".($lastseq).".'".$s->calcMethodCallSig. "'(".join(",", @arglist). ")\n";

			}


	}
}
