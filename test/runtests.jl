using SequenceTokenizers
using Test
using Optimisers

@testset "SequenceTokenizer" begin
    alphabet = ['A', 'C', 'G', 'T']
    unksym = 'N'
    tokenizer = SequenceTokenizer(alphabet, unksym)

    @test length(tokenizer) == 5  # Alphabet + unksym
    @test tokenizer('A') == 2  # 'A' is at index 2
    @test tokenizer('N') == 1  # 'N' is at index 1 (unksym)
    @test tokenizer('Z') == 1  # Unrecognized symbol should return unkidx
    @test tokenizer(['A', 'C', 'T']) == [2, 3, 5]
    @test tokenizer([1, 2, 3]) == ['N', 'A', 'C']
    @test tokenizer([[2, 3], [4, 5]]) == [['A', 'C'], ['G', 'T']]

    # Test show method for SequenceTokenizer
    io = IOBuffer()
    Base.show(io, tokenizer)
    output = String(take!(io))
    @test output == "SequenceTokenizer{Char}(length(alphabet)=5, unksym=N)"

    # Test AbstractVector{Vector{T}} method for SequenceTokenizer
    batch = [['A', 'C'], ['G', 'T']]
    encoded_batch = tokenizer(batch)
    @test size(encoded_batch) == (2, 2)
    @test encoded_batch == [2 4; 3 5]

    # Test AbstractVector{Vector{Int}} method for SequenceTokenizer
    indices_batch = [[1, 2], [3, 4]]
    decoded_batch = tokenizer(indices_batch)
    @test decoded_batch == [['N', 'A'], ['C', 'G']]

    # Test AbstractMatrix{Int} method for SequenceTokenizer
    indices_matrix = [1 2; 3 4]
    decoded_matrix = tokenizer(indices_matrix)
    @test decoded_matrix == ['N' 'A'; 'C' 'G']

    # Test case to trigger findfirst(isequal(unksym), alphabet)
    alphabet_with_unksym = ['N', 'A', 'C', 'G', 'T']
    tokenizer_with_existing_unksym = SequenceTokenizer(alphabet_with_unksym, 'N')
    @test tokenizer_with_existing_unksym.unkidx == 1  # 'N' should be found at index 1

    # Test Optimisers.trainable method
    @test length(Optimisers.trainable(tokenizer)) == 0
end
