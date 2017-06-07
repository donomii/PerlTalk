#Must declare some packages here or the perl parser goes wonky
package Node;
sub athing{}
package LinkList;
sub athing {}
package Neo;
package Cell;
use base "LinkList";
use Data::Dumper;
sub new {
	my $o = bless {};
	return $o;
}

sub  eatArray {
	my ($s) = @_;
	my $c = new Neo;
	$c->input($s->input());
	$c->prev($s);
	$s->next($c);
	$c->eat();
	if (scalar(@{$s->{input}})){return $c->eatArray();}
	else{
		my $e = new Neo;
		$e->prev($e);
		$e->next(undef);
		$c->next($e);
		return $c}
}
sub become {
	my ($s, $new) = @_;
	$s->{pheno} = $new;
	bless $s, $new;
}



sub input {
	my ($s, $val) = @_;
	if ($val) { $s->{input} = $val;}
	return $s->{input};
}

sub eat {
	my ($s) = @_;
	my $in = $s->{input};
	$s->{content} = shift @{$in};
	$s->setpheno();
}
sub dump {
	my ($s) = @_;
	print "[".$s->pheno.":".$s->{content}, "] ";
#print "[".$s->pheno.":".$s->{content}, "] ";
#print "[".$s->{content}, "]-";
	if ($s->next()){$s->next()->dump();}
}

sub setpheno {
	my ($s) = @_;
	my $c = $s->{content};
	$s->{pheno} = $c;
	if ($c =~ /^[a-zA-Z0-9]+$/) {$s->become( "ALPHANUM")}
	if ($c =~ /^[0-9]+$/) {$s->become(  "NUMBER")}
	if ($c =~ /^\s+$/) {$s->become( "WHITESPACE")}
	if ($c =~ /\r|\n/) {$s->become(  "NEWLINE")}
	if ($c eq "'") {$s->become( "STRINGTERM")}
	if ($c eq '"') {$s->become( "QUOTETERM")}
	if ($c eq '#') {$s->become( "LINECOMMENT")}
	if ($c eq ':') {$s->become( "COLON")}
	if ($c eq '.') {$s->become("TERMINATOR")}
	if ($c eq '[') {$s->become( "STARTANON")}
	if ($c eq ']') {$s->become( "ENDANON")}
	if ($c eq '|') {$s->become( "VBAR")}
	if ($c eq '^') {$s->become( "RETURN")}
	if ($c eq '(') {$s->become( "STARTEXPRESSION")}
	if ($c eq ')') {$s->become( "ENDEXPRESSION")}
	return $c;
}



sub isNum {
	my ($s) = @_;
	if ($s->{content} =~ /^[0-9]+$/) {return 1;} else {return 0;}
}

sub incorporatenext{
	my ($s)=@_;
	my $t= $s->next->is;
	$s->{organelles}->{$t} = $s->next;
	$s->next($s->next->next);
	$s->next->prev($s);
}
sub makenodes {
	my $s = shift;
#print "Making node for ".$s->pheno."\n";
	my $n = new Node;
	$n->{origin} = $s;
	$n->{pos} = $s->{pos};
	$n->{content} = $s->{content};
	$n->{pheno} = $s->pheno;
#$n->{first} = $s;
#$n->{last} = $s;
	if($s->prev){
		$n->{prev} = $s->prev->{parent};
		$n->{prev}->{next} = $n; 
	}
	$s->{parent} = $n;
#print "Done making node for ".$s->pheno."\n";
	unless($s->is eq "END"){return $s->next->makenodes ;}
	return $n;
}

sub a {}
sub b{}

sub doStuff {
	my ($s) = @_;
	if($s->is eq "WHITESPACE") { $s->suicide;}
	if($s->is eq "NEWLINE") { $s->suicide;}
	if($s->is eq "QUOTE") { $s->suicide;}
	return unless $s->prev();
	return unless $s->next();


	$s->b;
#print "Comparing ".$s->{content}." with ". $s->next->is."\n";
}

sub engulfnext {
	my ($s) = @_;
	$s->{content} = $s->{content} . $s->next->{content};
	$s->next($s->next->next);
	$s->next->prev($s);
}


sub engulfprev {
	my $s = shift;
	$s->{content} = $s->prev->{content} . $s->{content};
	$s->prev($s->prev->prev());
	$s->prev->next($s);
}
sub mergewithprev {
	my ($s, $target) = @_;
	$s->{content} = $target->{content} . $s->{content};
	$s->prev($target->prev());
	$s->prev()->next($s);
}



package START; use base "Cell";
package VARIABLENAME; use base "Cell";
sub b {my $s = shift;
	$s->brule ( [ "ANY", "VARIABLENAME", "ASSIGNMENT" ] => "VARIABLETOBEASSIGNED");
	$s->brule ( [ "ANY", "VARIABLENAME", "DECLAREVARIABLE" ] => "DECLAREVARIABLE");}

	package COLON; use base "Cell";
	sub b {
		my $s = shift;

		if (($s->prev->is eq "ALPHANUM")||($s->prev->is eq "IDENTIFIER"))
		{ $s->become("ARGNAME");
			$s->engulfprev();}

			if (($s->next->pheno eq "ALPHANUM")||($s->next->pheno eq "IDENTIFIER"))
			{ $s->become("ANONPARAMNAME");
				$s->engulfnext();}
	}

package ALPHANUM; use base "Cell";
sub b {my $s = shift;
	if (($s->pheno ne $s->next->pheno)&& ($s->pheno ne $s->prev->pheno)) {$s->become( "IDENTIFIER")}}

	package TERMINATOR; use base "Cell";
	sub b { 
		my $s = shift;
		$s->rule ( [ "NUMBER", "TERMINATOR", "NUMBER" ] => sub {$s->engulfnext;$s->prev->engulfnext; } );
	}

package ARGNAME; use base "Cell";
sub b{
	my $s = shift;
#if ($s->prev->is eq "IDENTIFIER") { $s->engulfprev}
#if ($s->next->is ne "ARGNAME") {$s->incorporatenext} 
}

package IDENTIFIER; use base "Cell";
sub b {
	my $s = shift;
	$s->brule ( [ "ASSIGNMENT",    "IDENTIFIER", "ANY" ] => "VARIABLENAME");
	$s->brule ( [ "RETURN",        "IDENTIFIER", "ANY" ] => "VARIABLENAME");
	$s->brule ( [ "ANONPARAMLIST", "IDENTIFIER", "ANY" ] => "VARIABLENAME");
	$s->brule ( [ "ARGNAME",       "IDENTIFIER", "ANY" ] => "VARIABLENAME");
	$s->brule ( [ "VBAR",          "IDENTIFIER", "VBAR" ] => "DECLAREVARIABLE");
	$s->brule ( [ "VBAR",          "IDENTIFIER", "ANY" ] => "VARIABLENAME");
	$s->brule ( [ "DECLAREVARIABLE","IDENTIFIER", "ANY" ] => "VARIABLENAME");
	$s->brule ( [ "VARIABLENAME",  "IDENTIFIER", "ANY" ] => "NOARGSCALL");
	$s->brule ( [ "NUMBER",        "IDENTIFIER", "ANY" ] => "NOARGSCALL");
	$s->brule ( [ "STRING",        "IDENTIFIER", "ANY" ] => "NOARGSCALL");
	$s->brule ( [ "IDENTIFIER", "IDENTIFIER", "TERMINAL" ], => "NOARGSCALL");
	$s->brule ( [ "IDENTIFIER", "IDENTIFIER", "ARGNAME" ]=> "NOARGSCALL" );
	$s->brule ( [ "TERMINATOR", "IDENTIFIER", "ANY" ]    =>     "VARIABLENAME");
	$s->brule ( [ "STARTANON", "IDENTIFIER", "ANY" ]    =>     "VARIABLENAME");
	$s->rule  ( [ "ANY", "IDENTIFIER", "VBAR" ], sub { $s->become("DECLAREVARIABLE");$s->runback;$s->next->suicide});
	$s->brule ( [ "ANY", "IDENTIFIER", "DECLAREVARIABLE" ] =>"DECLAREVARIABLE"); 
#$s->rule  ( [ "ANY", "IDENTIFIER", "METHODSIG" ], sub { $s->become("DECLAREVARIABLE");$s->runback;});

}

package WHITESPACE; use base "Cell";
package NEWLINE; use base "Cell";
package NUMBER; use base "Cell";
package STRINGTERM; use base "Cell";
package NOARGSCALL; use base "Cell";
sub b { my $s = shift; $s->brule ( [ "ANY", "NOARGSCALL", "DECLAREVARIABLE" ] => "DECLAREVARIABLE");}
package STARTANON; use base "Cell";
package ENDANON; use base "Cell";
package STARTEXPRESSION; use base "Cell";
package ENDEXPRESSION; use base "Cell";
package QUOTETERM; use base "Cell";
package END; use base "Cell";
package ASSIGNMENT; use base "Cell";
package STRING; use base "Cell";
package ANONPARAMNAME; use base "Cell";
package QUOTE; use base "Cell";
package DECLAREVARIABLE; use base "Cell";
package VARIABLETOBEASSIGNED; use base "Cell";
package RETURN; use base "Cell";
package METHODSIG; use base "Cell";
package VBAR; use base "Cell";
sub b {
	my $s = shift;
	$s->brule ( [ "ANONPARAMNAME", "VBAR", "ANY" ] => "ANONPARAMLIST");
	$s->brule ( [ "ANY", "VBAR", "DECLAREVARIABLE" ] =>"METHODSIG"); 
	$s->brule ( [ "ANY", "VBAR", "VBAR" ] =>"METHODSIG"); 
}
package ANONPARAMLIST; use base "Cell";

package Neo;use base "Cell";

sub doStuff{
	my $s = shift;
	return unless $s->prev();
	return unless $s->next();
	$s->rule ( [ "ANY", "ANY", "=" ], sub {$s->engulfnext;$s->become("ASSIGNMENT");} );
	$s->rule ( [ "ANY", "STRINGTERM", "ANY" ], sub { $s->become("OPENSTRING");$s->{content}=""} );
	if($s->is eq "OPENSTRING"){
		if ($s->next->is eq "STRINGTERM"){$s->engulfnext;$s->become("STRING");}
		else {$s->engulfnext;$s->doStuff;}}

	if ($s->is eq "QUOTETERM"){ $s->become("OPENQUOTE");$s->{content}=""} 
	if($s->is eq "OPENQUOTE"){
		if ($s->next->is eq "QUOTETERM"){$s->engulfnext;$s->become("QUOTE");}
		else {$s->engulfnext;$s->doStuff;}}

	if ($s->is eq $s->next()->is) { $s->engulfnext}
	if ($s->is eq $s->prev()->is) { $s->engulfprev}
	$s->rule  ( [ "ANY", "ALPHANUM", "NUMBER" ], sub { $s->engulfnext;});
}

sub evolve {
	my $s = shift;
#print "Making node for ".$s->pheno."\n";
	my $n = new Cell;
	$n->{origin} = $s;
						$n->{pos} = $s->{pos};
	$n->{content} = $s->{content};
	$n->become($s->pheno);
	$n->{first} = $s;
	$n->{last} = $s;
	if($s->prev){
		$n->{prev} = $s->prev->{parent};
		$n->{prev}->{next} = $n; 
	}
	$s->{parent} = $n;
    if ($s->is eq 'STRING') { chop $n->{content}}
#print "Done making node for ".$s->pheno."\n";
	unless($s->is eq "END"){return $s->next->evolve ;}
	return $n;

}
sub become {
	my ($s, $new) = @_;
	$s->{pheno} = $new;
}

sub new {
	my $o = bless {};
	$o->{scents} = {};
	return $o;
}
1;
