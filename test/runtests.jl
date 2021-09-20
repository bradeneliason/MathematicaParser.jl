using MathematicaParser
using ParserCombinator
using Test

################################################################################
##                                                                            ##
#                                Unit Testing                                  #
#                                                                              #
################################################################################

@testset "Number conversion" begin
    @test parsemathematica("1")[1]         ==  1
    @test parsemathematica("-1")[1]        == -1
    @test parsemathematica("1.0000")[1]    ==  1
    @test parsemathematica("1.0000")[1]    !== 1.0
    @test parsemathematica("1.000001")[1]  ==  1.000001
    @test parsemathematica("1.2")[1]       ==  1.2
    @test parsemathematica("1.2e3")[1]     ==  1200
    @test parsemathematica("-1.2")[1]      == -1.2
end

# Testing variable name patterns
vartestdict = Dict(
    "x"         => :x,
    "x01"       => :x01,
    "xAx01xx"   => :xAx01xx,
    "x_1"       => :x_1,
    "x_1 "      => :x_1,
    " x_1 "     => :x_1,
    " x_1 "     => :x_1,
    "Xx01"      => :Xx01,
    "A"         => :A,
)
@testset "Variable Names" begin
    for (t,res) in vartestdict
        @test parsemathematica(t)[1] == res
    end
end

# Testing argument lists
argstestdict = Dict(
    "[x]"               => Args([:x]),
    "[a,b,c,z]"         => Args([:a, :b, :c, :z]),
    "[a, b,   c  ,z ]"  => Args([:a, :b, :c, :z]),
)
@testset "Argument List - No subexpressions" begin
    for (t,res) in argstestdict
        # Note Arguments on their own are not correct syntax
        # Need to import the args ParserCombinator type to parse args alone
        @test parse_one(t, MathematicaParser.args)[1] == res 
    end
end


# Model Function Test (no sub expressions)
funtestdict = Dict(
    "Log[x]"                        => Fun(:Log, [Args([:x])]),
    "Exp[x]"                        => Fun(:Exp, [Args([:x])]),
    "Log2[x]"                       => Fun(:Log2, [Args([:x])]),
    "ArcTan[x,y]"                   => Fun(:ArcTan, [Args([:x, :y])]),
    "Hypergeometric2F1[a,b,c,z]"    => Fun(:Hypergeometric2F1, [Args([:a, :b, :c, :z])]),
    "Derivative[n][f][x]"           => Fun(:Derivative, [Args([:n]), Args([:f]), Args([:x])]),
)
@testset "Function Parsing - No subexpressions" begin
    for (t,res) in funtestdict
        @test parsemathematica(t)[1] == res
    end
end


# parsemathematica("--x")
# parsemathematica("1+2+3")
# parsemathematica("Sin[x] * 1")
# parsemathematica("1+2+3")
# parsemathematica("1 + 2+ 3")
# parsemathematica("1 + 2+ Sin[x]")
# parsemathematica("1 + (2+3)")
# parsemathematica("1 + (2*3)")
# parsemathematica("1 + 2*3")
# parsemathematica("-1/(Sin[x])")
# parsemathematica("Sin[x,y]")
# parsemathematica("Derivative[n,a][f][x]")
# parsemathematica("Sinh[c - b*x]")
# parsemathematica("x^7")
# parsemathematica("2*x^7")
# parsemathematica("a^b")
@test parsemathematica("a^b^c")[1] ==  Pow(:a, [:b, :c])

# Challenge cases:
# TODO:
# "(e x)^m/((a + b*x^3)*(c + d*x^3))"
# "(g[x]*Derivative[1][f][x] + f[x]*g'[x])/(1 - f[x]^2*g[x]^2)"
# "(a c e+(b c e+a d e+a c f) x+(b d e+b c f+a d f) x^2+b d f x^3)^2"
# "E^ArcTan[a*x]/(c + a^2*c*x^2)^(5/2)"
# "-((4*(d*x)^(3/2)*HypergeometricPFQ[{3/2,3/2},{5/2,5/2},(-b)*x])/(9*d))+(Sqrt[Pi]*Sqrt[d*x]*Log[x])/(2*b*Sqrt[b*x])"
# "If[$VersionNumber>=8,-((2*C*(b*Sec[c+d*x])^n*Sin[c+d*x])/(d*(3-2*n)*Sec[c+d*x]^(3/2)))-(2*(A*(3-2*n)+C*(5-2*n))*Hypergeometric2F1[1/2,(1/4)*(7-2*n),(1/4)*(11-2*n),Cos[c+d*x]^2]*(b*Sec[c+d*x])^n*Sin[c+d*x])/(d*(3-2*n)*(7-2*n)*Sec[c+d*x]^(7/2)*Sqrt[Sin[c+d*x]^2])-(2*B*Hypergeometric2F1[1/2,(1/4)*(5-2*n),(1/4)*(9-2*n),Cos[c+d*x]^2]*(b*Sec[c+d*x])^n*Sin[c+d*x])/(d*(5-2*n)*Sec[c+d*x]^(5/2)*Sqrt[Sin[c+d*x]^2]),-((2*C*(b*Sec[c+d*x])^n*Sin[c+d*x])/(d*(3-2*n)*Sec[c+d*x]^(3/2)))-(2*(A*(3-2*n)+C*(5-2*n))*Hypergeometric2F1[1/2,(1/4)*(7-2*n),(1/4)*(11-2*n),Cos[c+d*x]^2]*(b*Sec[c+d*x])^n*Sin[c+d*x])/(d*(21-20*n+4*n^2)*Sec[c+d*x]^(7/2)*Sqrt[Sin[c+d*x]^2])-(2*B*Hypergeometric2F1[1/2,(1/4)*(5-2*n),(1/4)*(9-2*n),Cos[c+d*x]^2]*(b*Sec[c+d*x])^n*Sin[c+d*x])/(d*(5-2*n)*Sec[c+d*x]^(5/2)*Sqrt[Sin[c+d*x]^2])]"
# "-((2*(1 - 1/x^2)^(1/4)*Sqrt[e*x]*EllipticE[ArcCsc[x]/2, 2])/(e^2*(1 - x^2)^(1/4)))"
# "7*a^6*b*x + (21*a^5*b^2*x^2)/2 + (35*a^4*b^3*x^3)/3 + (35*a^3*b^4*x^4)/4 + (21*a^2*b^5*x^5)/5 + (7*a*b^6*x^6)/6 + (b^7*x^7)/7 + a^7*Log[x]"
