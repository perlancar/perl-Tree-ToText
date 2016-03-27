package Tree::ToTextLines;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(render_tree_as_text);

sub _render {
    my ($opts, $node, $is_last_childs) = @_;

    my $level = @$is_last_childs;

    my $res = "";

    # draw indent
    for my $l (1..$level) {
        if ($opts->{show_guideline}) {
            if ($is_last_childs->[$l-1]) {
                $res .= ($l == $level ? "\\" : " ");
            } else {
                $res .= ($l == $level ? "|" : "|");
            }
            $res .= ($l == $level ? "-" : " ") x $opts->{indent};
            $res .= " ";
        } else {
            $res .= " " x $opts->{indent};
        }
    }

    # show attributes
    {
        my $id;
        if (defined (my $meth = $opts->{id_attribute})) {
            $id = ($opts->{show_attribute_name} ? "$meth:" : "") . $node->$meth;
        } else {
            $id = "$node";
        }
        $id =~ s/\R.*//s;
        $res .= $id;

        # XXX show class name
        if ($opts->{show_class_name}) {
            my $class = ref($node);
            $res .= " " .
                ($opts->{show_attribute_name} ? "_class:":"") .
                $class;
        }

        # XXX show extra attributes
        if ($opts->{extra_attributes}) {
            for my $attr (@{ $opts->{extra_attributes} }) {
                my $v = $node->$attr;
                $v =~ s/\R.*//s;
                $res .= " ".($opts->{show_attribute_name} ? "$attr:" : "") . $v;
            }
        }
    }

    $res .= "\n";

    my @children = $node->children;
    @children = @{$children[0]} if @children==1 && ref($children[0]) eq 'ARRAY';
    my @children_res;

    for my $i (0..$#children) {
        my $is_last_child = $i == $#children ? 1:0;
        push @children_res,
            _render($opts, $children[$i], [@$is_last_childs, $is_last_child]);
    }

    ($res, @children_res);
}

sub render_tree_as_text {
    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
        $opts = {%$opts}; # shallow clone
    } else {
        $opts = {};
    }
    $opts->{indent} //= 2;
    $opts->{show_guideline} //= 0;
    $opts->{id_attribute} //= undef;
    $opts->{show_attribute_name} //= 1;
    $opts->{show_class_name} //= $opts->{id_attribute} ? 1:0;
    $opts->{extra_attributes} //= undef;

    my $tree = shift;

    join("", _render($opts, $tree, []));
}

# TODO: render each node as CSV line, LTSV line, JSON, or Perl hash for greater
# flexibility.

1;
# ABSTRACT: Render a tree object as indented text lines

=head1 SYNOPSIS

 use Tree::ToTextLines qw(render_tree_as_text);

 my $tree = ...; # you can build a tree e.g. using Tree::FromStruct or Tree::FromTextLines

 print render_tree_as_text({
     #indent             => 2,
     show_guideline      => 1,        # default: 0
     id_attribute        => 'id',     # default: undef
     show_attribute_name => 0,        # default: 1
     show_class_name     => 0,        # default: 1
     #extra_attributes => [..., ...], # default: undef
 }, $tree);

Sample output:

 root
 |-- child1
 |   \-- grandc1
 |-- child2
 |-- child3
 |   |-- grandc2
 |   |-- grandc3
 |   |  |-- grandgrandc1
 |   |  \-- grandgrandc2
 |   |-- grandc4
 |   \-- grandc5
 \-- child4


=head1 DESCRIPTION


=head1 FUNCTIONS

=head2 render_tree_as_text_lines([ \%opts, ] $tree) => str

This function renders a tree object C<$tree> as lines of text, each line showing
the ID or attributes of a node. Each line will be indented differently according
to the node's position. A child node will be indented more deeply than its
parent node.

Tree object of any kind of class is accepted as long as the class responds to
C<children> (see L<Role::TinyCommons::Tree::Node> for more details on the
requirement).

This function is the complement for C<build_tree_from_text_lines> function in
L<Tree::FromTextLines>.

Available options:

=over

=item * indent => int (default: 2)

Number of spaces for each indent level.

=item * id_attribute => str (default: undef)

Name of ID attribute. If ID attribute is not specified, each node will be shown
as stringified object (only first line used), e.g.:

 Tree::Object::Hash=HASH(0x209a160)
   Tree::Object::Hash=HASH(0xfc9160)
   Tree::Object::Hash=HASH(0xac7160)

If ID attribute is used, the value of this attribute will be used instead, e.g.:

 id:node0
   id:node1
   id:node2

=item * extra_attributes => array of str (default: undef)

=item * show_class_name => bool (default: 1 or 0 if id_attribute is set)

=item * show_attribute_name => bool (default: 1)

=item * show_guideline => bool (default: 0)

=back


=head1 SEE ALSO

L<Tree::FromText>, L<Tree::FromTextLines>

L<Tree::FromStruct>
