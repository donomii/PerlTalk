use strict;
use PPI;
use Params::Util qw{_INSTANCE};
my @doc = <STDIN>;
my $doc =  join("",@doc);
my $m = PPI::Document->new(\$doc);
use Data::Dumper;
#print Dumper $m->{children};
#print foreach @{ dumpSexpr($m)};
my $o = dumpSexpr($m);
foreach (1..10) {
$o =~ s/\)\s+\)/\)\)/g;
$o =~ s/\n\)/\)/g;
$o =~ s/;\s*\)/\)/g;
$o =~ s/(\s),(\s*)\)/$1\)/g;
$o =~ s/\n([^ 	\(])/ $1/g;
}
print $o;


sub dumpSexpr {
    my $Element = shift;#_INSTANCE($_[0], 'PPI::Element') ? shift : $_[0];
    my $indent  = shift || '';
    my $output  = shift || '';

    # Recurse into our children
    if ( $Element->isa('PPI::Node') ) {
        my $child_indent = $indent . " ";
   # Add the content
        my $content = $Element->content;
        $content =~ s/\n/\\n/g;
        $content =~ s/\t/\\t/g;
        $content =~ s/\f/\\f/g;
        $content =~ s/\;/💋/g;
        #print ref($Element).":".$content, "\n\n";

    } elsif ( $Element->isa('PPI::Structure') ) {
        # Add the content
            my $start =  ($Element->start
                ? $Element->start->content
                : '(');
            my $finish = ($Element->finish
                ? $Element->finish->content
                : ')') . "\n" ;
            #print "  \t$start ... $finish";
    } 


if ( $Element->isa('PPI::Node' ) ){
    my @c = $Element->schildren;

    if (@c) {
        if ($#c>1) {
            $output .= "( ";  #Check recurse depth here, if it is >1 there are sub-expressions, and we need a begin
        }
        else {
            $output .= "( ";
        }
        
        foreach my $child (@c) {
                 
            $output .= dumpSexpr($child, $indent);
        }
    $output .= ")\n";
    }
} else {
    if (ref ($Element) =~ /PPI::Token::Quote::Single/) {
        my $c =  $Element->content;
        $c =~ s/;$//g;
        $output .= '"'.$c.'" ';
    } else {
        my $c =  $Element->content." ";
        #$c =~ s/;/SCOL/g;
        $c =~ s/;$//g;
        $c =~ s/;/💋/g;
        #print ref($Element) .":".$Element->content." ";
        $output .= $c;
    }

}

    return $output;
}

