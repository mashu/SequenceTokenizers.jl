using SequenceTokenizers
using Test

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

    # Test AbstractString method for SequenceTokenizer
    @test tokenizer("ACGT") == [2, 3, 4, 5]
    @test tokenizer("ACGTN") == [2, 3, 4, 5, 1]
    @test tokenizer("ACGTX") == [2, 3, 4, 5, 1]  # 'X' should be treated as unknown
    @test tokenizer("") == Int32[]  # Empty string should return empty array

    # Test AbstractVector{<:AbstractString} method for SequenceTokenizer
    batch = ["ACG", "TGC", "NNA"]
    result = tokenizer(batch)
    @test size(result) == (3, 3)
    @test result == [2 5 1; 3 4 1; 4 3 2]

    # Test with strings of different lengths
    batch_diff_lengths = ["A", "CG", "TGC"]
    result_diff_lengths = tokenizer(batch_diff_lengths)
    @test size(result_diff_lengths) == (3, 3)
    @test result_diff_lengths == [2 3 5; 1 4 4; 1 1 3]

    # Test with empty string in batch
    batch_with_empty = ["ACG", "", "TGC"]
    result_with_empty = tokenizer(batch_with_empty)
    @test size(result_with_empty) == (3, 3)
    @test result_with_empty == [2 1 5; 3 1 4; 4 1 3]

    # Test case to trigger findfirst(isequal(unksym), alphabet)
    alphabet_with_unksym = ['N', 'A', 'C', 'G', 'T']
    tokenizer_with_existing_unksym = SequenceTokenizer(alphabet_with_unksym, 'N')
    @test tokenizer_with_existing_unksym.unkidx == 1  # 'N' should be found at index 1

    # Test onehot_batch
    batch = Int32[2 4; 3 5; 1 2]  # Represents ['A', 'G'; 'C', 'T'; 'N', 'A']
    onehot_encoded = onehot_batch(tokenizer, batch)

    # Test with a sequence containing only unknown symbols
    unknown_seq = Int32[1, 1, 1]  # Represents "NNN"
    unknown_onehot = onehot_batch(tokenizer, unknown_seq)
    @test size(unknown_onehot) == (5, 3)
    @test all(unknown_onehot[1, :] .== 1)
    @test all(unknown_onehot[2:end, :] .== 0)

    # Test with a sequence containing repeated symbols
    repeated_seq = Int32[2, 2, 2]  # Represents "AAA"
    repeated_onehot = onehot_batch(tokenizer, repeated_seq)
    @test size(repeated_onehot) == (5, 3)
    @test all(repeated_onehot[2, :] .== 1)
    @test all(repeated_onehot[[1,3,4,5], :] .== 0)

    # Test with a sequence containing all possible tokens
    all_tokens_seq = Int32[1, 2, 3, 4, 5]  # Represents "NACGT"
    all_tokens_onehot = onehot_batch(tokenizer, all_tokens_seq)
    @test size(all_tokens_onehot) == (5, 5)
    # Check if the diagonal elements are all 1 and the sum is correct
    for i in 1:5
        @test all_tokens_onehot[i, i] == 1
        @test sum(all_tokens_onehot[:, i]) == 1
    end
    @test sum(all_tokens_onehot) == 5

    @test size(onehot_encoded) == (5, 3, 2)  # (num_tokens, seq_length, batch_size)
    @test onehot_encoded[:, 1, 1] == [0, 1, 0, 0, 0]  # 'A'
    @test onehot_encoded[:, 2, 1] == [0, 0, 1, 0, 0]  # 'C'
    @test onehot_encoded[:, 3, 1] == [1, 0, 0, 0, 0]  # 'N'
    @test onehot_encoded[:, 1, 2] == [0, 0, 0, 1, 0]  # 'G'
    @test onehot_encoded[:, 2, 2] == [0, 0, 0, 0, 1]  # 'T'
    @test onehot_encoded[:, 3, 2] == [0, 1, 0, 0, 0]  # 'A'

    # Test with an empty sequence
    empty_seq = Int32[]
    empty_onehot = onehot_batch(tokenizer, empty_seq)
    @test size(empty_onehot) == (5, 0)

    # Test onecold_batch
    decoded_batch = onecold_batch(tokenizer, onehot_encoded)
    @test size(decoded_batch) == size(batch)
    @test decoded_batch == ['A' 'G'; 'C' 'T'; 'N' 'A']

    # Test roundtrip: batch -> onehot -> onecold
    roundtrip_batch = onecold_batch(tokenizer, onehot_batch(tokenizer, batch))
    @test roundtrip_batch == ['A' 'G'; 'C' 'T'; 'N' 'A']

    # Test with different batch
    another_batch = Int32[1 3 5; 2 4 1]  # Represents ['N', 'C', 'T'; 'A', 'G', 'N']
    another_onehot = onehot_batch(tokenizer, another_batch)
    @test size(another_onehot) == (5, 2, 3)
    @test onecold_batch(tokenizer, another_onehot) == ['N' 'C' 'T'; 'A' 'G' 'N']
end
