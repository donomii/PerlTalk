package MyLang;
use strict;
my $in;

roundtrip( "if ( 1 == 1 ) [ 'true' println ] [ stuff ] ");
roundtrip( "if ( a == 1 ) [ 'true' println ] [ stuff [ this ( into ( that ) ) ] ] ");
roundtrip( "( 1 == 1 ) ( 2 == 2 ) ( 3 == 3 ) ");
roundtrip( "1 == 1 ; 2 == 2 ; 3 == 3 ");
roundtrip( "a = 1 ; b = 2 ; c = a + b ; c println ");
roundtrip( "declare a b c ; set a 1 ; set b 2 ; set c ( + a b ) ; c println ");
roundtrip( "declare a b c ; set a 1 ; set b 2 ; set c ( + a b ) ; if [ c ] [ println 'c is ' ; println c ] [ println c ] ");

sub debug{}
use Data::Dumper;
sub roundtrip {
    my $orig = shift;
    $in = $orig;
    $in = "[".$in."]";
    my $tree = lambda($in);
    my $out =  $tree->dumpnobr;
    print "\n* $orig\n* $out\n";
    if ($orig eq $out) { print "WIN\n" }else {print "FAIL\n";}
}
#while (1) {
    #my $inp = <>;
    #chomp $inp;
    #my $ret = run($inp);
    #print $ret->dump, "\n";
#}
    
sub run {
    my $orig = shift;
    my $env = shift;
    $in = $orig;
    $in = "[".$in."]";
    my $tree = lambda($in);
    my $out =  $tree->dumpnobr;
    print "\n* $orig\n* $out\n";
    if ($orig eq $out) { print "WIN\n" } else { print "FAIL\n"}
    return $tree->evaluate($env)->activate;
}

sub expr { debug( "Trying expr for $in\n"); (start_expr()||return undef); my $tail =  collect_expr("expression list");end_expr(); debug( Dumper ("Expression returned: ", $tail));return $tail; }
sub lambda { debug( "Trying lambda for $in\n"); (start_lambda()||return undef);# [ "args go here" ]
my $contents =  sequence();
end_lambda();
 #unshift @{$contents},  new Symbol ("Lambda");
debug( "Sequence returned in lambda: ".Dumper($contents));return new Lambda($contents)  ; }

sub statement {
#if we can find another statement after this, it's a separator, otherwise it's a terminator
    debug( "Trying statement separator on $in\n");
    my $maybe = collect_expr();
    return $maybe if $maybe;
    if ($in =~ m/^\s*(;+)\s*/){
        $in =~ s/^\s*(;+)\s*//;
        my $test = expr()||lambda()||collect_expr();
        if($test) {
            debug( "Statement separator returning $test\n");
            return ($test);
        }
    }
    return undef;
}

sub sequence {
    my $seq = shift||new Sequence([]);
    debug( "Attempting sequence\n");
    while (my $exp = expr() || lambda() || statement()){
        debug( "sequence got: ".Dumper($exp)."\n");
            $seq->appendseq($exp);
    }
    debug( "Leaving sequence",Dumper($seq),"\n");
    return $seq;
}

sub start_lambda { single_token('^\s*\[', "START-LAMBDA") }
sub end_lambda { single_token('^\s*\]', "END-LAMBDA") }
sub start_expr { single_token('^\s*\(', "START-EXPRESSION") }
sub end_expr { single_token('^\s*\)', "END-EXPRESSION") }
sub start_semi { single_token('^\s*\;', "START-EXPRESSION") }

sub single_token {
    my ($tok, $type) = @_;
    debug( "Trying to match $tok\n");
    if ($in=~m/^$tok/) {
        $in =~ s/^$tok//;
        return { type => $type}; #etc
    }
    return undef;
}

sub atom {
    debug( "Trying atom for $in\n");
    my $maybe = number()||string();
    debug( "maybe: $maybe\n");
    return $maybe if $maybe;
    if ($in =~ m/^\s*([-0-9a-zA-Z=+']+)+\s*/){
        my $atom = $1;
        $in =~ s/^\s*([-0-9a-zA-Z=+']+)+\s*//;
        debug( "res = $atom\n");
        return  new Symbol( $atom) ;
    }
    return undef;
}

sub number {
    debug( "Trying number for $in\n");
    if ($in =~ m/^\s*(\d+)\s*/){
      $in =~ s/^\s*(\d+)\s*//;
      return new Number($1);
   }
   return undef;
}

sub string {
    debug( "Trying string for $in\n");
    $in =~ s/^\s+//g;
    if ($in =~ m/^'/){
        $in =~ s/^'//;
        return new String( finish_string());
    }
    return undef;
}
sub finish_string {
    if ( $in=~ m/^'/) {
        $in =~ s/^'//;
        return "";
    }
    if ($in =~ m/^(.)/) {
        my $ret = $1;
        $in=~ s/^.//;
        return $ret . finish_string();
    }
}


sub collect_expr {
    my ( $explain, $type ) = @_;
    my $seq = new Expression({});
    debug( "Trying collect_tail for $in\n");
        while(my $res = expr()||lambda()||atom()){
        debug( "collect_tail: $res\n");
        #$res = new Expression($res);
        $seq->appendexpr($res);
}
        if ($seq->isEmpty) {
            return undef}
            else{
        return $seq;
            }

package NativeCall;
sub new { bless {content=>$_[1], type=>"NATIVECALL"} }
sub value { $_[0]->{content}}
package Number;
sub new { bless {content=>$_[1], type=>"NUMBER"} }
sub dump { $_[0]->value." " }
sub dumpbracefree { my $self = shift;$self->dump(@_) }
sub value { $_[0]->{content}}
package Symbol;
sub new { bless {content=>$_[1], type=>"SYMBOL"} }
sub dump { $_[0]->{content}." " }
sub dumpbracefree { my $self = shift;$self->dump(@_) }
sub value { $_[0]->{content}}
package String;
sub new { bless {content=>$_[1], type=>"STRING"} }
sub dump { "'".$_[0]->value."' " }
sub dumpbracefree { my $self = shift;$self->dump(@_) }
sub value { $_[0]->{content}}
package Expression;
sub value { $_[0]->{content}}
sub new { shift;my $obj = shift;bless $obj; $obj->{content} ||=[]; return $obj }
sub dump { my $self = shift; join( "", "( ", $self->dumpnobr, ") ") }
sub dumpnobr { my $self = shift; join ("", map {$_->dump} @{$self->value}) }
sub dumpbracefree { my $self = shift; join("",  join("", map {$_->dumpbracefree} @{$self->value}) ) }
    sub appendexpr { my ($self, $app) = @_; return unless $self&&$app; push @{$self->value}, $app}
    sub isEmpty { my $self = shift;  if (scalar(@{$self->value})==0){ return 1 } else { return 0};}
package Sequence;
sub new { shift;bless shift }
sub dump { my $self = shift; join("", map {$_->dump} @{$self} )}
sub appendseq { my ($self, $app) = @_; return unless $self&&$app; push @{$self}, $app}
sub value { $_[0]->{content}}
package Lambda;
use Data::Dumper;
sub new { my $pkg = shift;my $content = shift; bless { content => $content}  }
sub dump { my $self = shift; join("", "[ ", $self->dumpnobr , "] ") }
sub dumpbracefree { my $self = shift; join("", "[ ", join(" ; ", map {$_->dumpbracefree} @{$self->{content}}) , "] ") }
sub dumpnobr { my $self = shift; join("; ", map {$_->dumpnobr} @{$self->{content}}) }
sub appendexpr { my ($self, $app) = @_; return unless $self&&$app; push @{$self->{content}}, @{$app}}
sub value { $_[0]->{content}}
}
