module MathematicaParser

export parsemathematica
export MxNode, Args, Fun, Inv, Neg, Pow, Prd, Sum

using ParserCombinator

################################################################################
##                                                                            ##
#                      Stucts and Utility Functions                            #
#                                                                              #
################################################################################

abstract type MxNode end

Base.:(==)(n1::MxNode, n2::MxNode) = n1.val == n2.val

struct Sum<:MxNode
    val
    function Sum(v::Vector)
        # Only create a Sum type if the input has 2+ inputs
        if length(v) == 1
            return v[1]
        else
            return new(v)
        end
    end
end

struct Prd<:MxNode
    val
    function Prd(v::Vector)
        # Only create a Prd type if the input has 2+ inputs
        if length(v) == 1
            return v[1]
        else
            return new(v)
        end
    end
end

struct Neg<:MxNode val end
struct Inv<:MxNode val end

struct Pow<:MxNode
    base
    expn
    function Pow(b, v)
        # Only create a Pow type if there is a nonempty second argument
        if length(v) == 0
            return b
        elseif length(v) == 1
            return new(b, v[1])
        else
            # If there is a "power tower" like 2^3^5
            return new(b, Pow(v[1], v[2:end]))
        end
    end
end

Base.:(==)(p1::Pow, p2::Pow) = (p1.base == p2.base) && (p1.expn == p2.expn)


struct Args<:MxNode val end

struct Fun<:MxNode
    fun
    argsets::Vector{Args}
end

Base.:(==)(f1::Fun, f2::Fun) = (f1.fun == f2.fun) && (f1.argsets == f2.argsets)


# TODO: How to convert to other number types?
#   - Complex numbers & im
#   - Rationals
#   - Special numbers like pi
"""
    pnum(x)

Parses a string of a number into a number. If the string parses to an Int
without an InexactError, then it returns an Int type, otherwide returns
a Float type.
"""
function pnum(x)
    xfl = parse(Float64, x)
    try 
        return convert(Int, xfl)  # catches inexact errors
    catch
        return xfl
    end
end


################################################################################
##                                                                            ##
#                                 Basic patterns                               #
#                                                                              #
################################################################################

# whitespace:
spc = "([\t ]+|[\r\n]+(#.*)?)"
wstar(x) = string(x, spc, "*")   # A pattern x with possible whitespace
wplus(x) = string(x, spc, "+")   # A pattern x with 1+ whitespaces
spc_star = ~Pattern(spc)[0:end]  # Matches and drops any number of spaces

# Bracketing
par_beg = E"(" + spc_star
par_end = E")" + spc_star
sqr_beg = E"[" + spc_star
sqr_end = E"]" + spc_star
crl_beg = E"{" + spc_star
crl_end = E"}" + spc_star

# Special characters
# Pi = p"Pi"
# parse_one("Pi", Pi)
# parse_one("Piedmont", Pi)

# A pattern for numbers
# evaluates the number with the function pnum
num = Pattern(wstar("-?(\\d*\\.?\\d+|\\d+\\.\\d*)([eE]-?\\d+)?")) > pnum

# A pattern for variable names
varpat = p"[A-Za-z][A-Za-z\d_]*(?![\w]*\[)" > Symbol
# varpat = p"[a-z][A-Za-z\d_]*(?![\w]*\[)" > Symbol
var = spc_star + varpat + spc_star


add_op = E"+" + spc_star 
sub_op = E"-" + spc_star
mul_op = E"*" + spc_star
div_op = E"/" + spc_star

pow_op = E"^" + spc_star


################################################################################
##                                                                            ##
#                                 Expressions                                  #
#                                                                              #
################################################################################


expr = Delayed();

# Pattern for arguments
#   ⋅ Starts with "[", includs one or more sub expression separated by a comma
#   ⋅ Creates an Args types from the input
#   ⋅ Ends with a "]"
args = sqr_beg + (expr + (P"," + expr)[0:end] |> collect > Args) + sqr_end;

# A pattern for Functions
# Starts with a capital letter and is followed by 1 or more argument sets
# TODO: single letter functions including lower case
fun = p"[A-Z][a-zA-Z\d]*" + args[1:end] |> f -> Fun(Symbol(f[1]), f[2:end]);

# Pattern for a "value" which can be...
#   ⋅ a subexpression in parentheses,
#   ⋅ a function,
#   ⋅ a number, or
#   ⋅ a variable 
val = (par_beg + expr + par_end) | fun | num | var;

# TODO: perhaps have different behaviors for -(x+2) and -2
#   ⋅ -(x+2) could create a Neg type
#   ⋅ -2 could parse to a number
neg = Delayed();
neg.matcher = val | (E"-" + neg > Neg); # allow multiple (or no) negations (eg ---3)

pow = neg + (pow_op + neg)[0:end] |> x -> Pow(x[1], x[2:end]);

mul = mul_op + pow;
div = div_op + pow > Inv;
prd = pow + (mul | div)[0:end] |> Prd;

add = add_op + prd;
sub = sub_op + prd > Neg;

expr.matcher = prd + (add | sub)[0:end] |> Sum;


function parsemathematica(s::AbstractString)
    try
        parse_one(s, expr)
    catch
        @warn "Cannot parse expression: $s"
    end
end

parse_one("[x]", args)
parse_one("Sin[x]", fun)

end
