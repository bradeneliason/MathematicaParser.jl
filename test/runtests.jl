using MathematicaParser
using ParserCombinator
using Test

################################################################################
#                                                                              #
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
    "[x]"               => MathematicaParser.Args([:x]),
    "[a,b,c,z]"         => MathematicaParser.Args([:a, :b, :c, :z]),
    "[a, b,   c  ,z ]"  => MathematicaParser.Args([:a, :b, :c, :z]),
)
@testset "Argument List - No subexpressions" begin
    for (t,res) in argstestdict
        # Note Arguments on their own are not correct syntax
        # Need to import the args ParserCombinator type to parse args alone
        # @info parse_one(t, MathematicaParser.args)[1]
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


# Order of operations
@testset "Order of Operations" begin
    @test parsemathematica("a^b")[1] ==  Pow(:a, :b)
    @test parsemathematica("a^b^c")[1] ==  Pow(:a, Pow(:b, :c))
    @test parsemathematica("2+3*4")[1] == Sum([2, Prd([3, 4])])
    @test parsemathematica("4*-6*(3 * 7 + 5) ")[1] == Prd([4, -6, Sum([Prd([3, 7]), 5])])
    @test parsemathematica("7^-3*2")[1] == Prd([Pow(7, -3), 2])
end


parsemathematica("Gamma[x,2*x]/x^3")
parsemathematica("Gamma[x, 2*x]/x^3")

afuntestdict = [
    "f[x]"              => Fun(:f, Args[Args([:x])]),
    "f'[x]"             => Fun(:Derivative, Args[Args(1), Args(:f), Args([:x])]),
    "f''[x]"            => Fun(:Derivative, Args[Args(2), Args(:f), Args([:x])]),
    "f'''[x]"           => Fun(:Derivative, Args[Args(3), Args(:f), Args([:x])]),
    "f'[x]/f[x]"        => Prd([Fun(:Derivative, Args[Args(1), Args(:f), Args([:x])]), Inv(Fun(:f, Args[Args([:x])]))]),
    "Sin[x] + f'[x]"    => Sum([Fun(:Sin, Args[Args([:x])]), Fun(:Derivative, Args[Args(1), Args(:f), Args([:x])])]),
    "f[g'[x]]"          => Fun(:f, Args[Args([Fun(:Derivative, Args[Args(1), Args(:g), Args([:x])])])]),
]
@testset "Derivative shorthand" begin
    for (t,r) in afuntestdict
        @test parsemathematica(t)[1] == r
    end
end


convtestdict = [
    "1*2 + 3"           => :(1 * 2 + 3),
    "3^7^8"             => :(3 ^ (7 ^ 8)),
    "3/8"               => :(3 * (1 / 8)),
    "-5 +9"             => :(-5 + 9),
    "Sin[x]"            => :(Sin(x)),
    "-Sin[x]"           => :(-1 * Sin(x)),
    "Sin[a,b][y][z]"    => :(Sin(a, b, y, z)),
    "4*-6*(3 ^ 7 + 5) + Sin[x]" => :(4 * -6 * (3 ^ 7 + 5) + Sin(x)),
]
@testset "Conversion to Expressions" begin
    for (t,r) in convtestdict
        # println( parsemathematica(t)[1])
        # println(toexpr(parsemathematica(t)[1]))
        @test toexpr(parsemathematica(t)[1]) == r
    end
end
