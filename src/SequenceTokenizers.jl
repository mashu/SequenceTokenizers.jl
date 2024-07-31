module SequenceTokenizers
    using Functors
    using Optimisers

    export SequenceTokenizer

    """
        SequenceTokenizer(alphabet::Vector{T}, unksym::T) where T

    Tokenizes character sequences.

    # Arguments
    - `alphabet::Vector{T}`: A vector of symbols to be tokenized.
    - `unksym::T`: The symbol for unknown tokens.

    # Returns
    - `SequenceTokenizer{T}`: A `SequenceTokenizer` object.
    """
    struct SequenceTokenizer{T, V <: AbstractVector{T}}
        alphabet::V
        lookup::Dict{T, Int32}
        unksym::T
        unkidx::Int32

        function SequenceTokenizer(alphabet::V, unksym::T) where {T, V <: AbstractVector{T}}
            if !(unksym ∈ alphabet)
                alphabet = vcat(unksym, alphabet)
                unkidx = Int32(1)
            else
                unkidx = findfirst(isequal(unksym), alphabet)
            end
            lookup = Dict(x => Int32(idx) for (idx, x) in enumerate(alphabet))
            new{T, V}(alphabet, lookup, unksym, unkidx)
        end
    end

    Base.length(tokenizer::SequenceTokenizer) = length(tokenizer.alphabet)

    function Base.show(io::IO, tokenizer::SequenceTokenizer{T}) where T
        print(io, "SequenceTokenizer{$(T)}(length(alphabet)=$(length(tokenizer)), unksym=$(tokenizer.unksym))")
    end

    function (tokenizer::SequenceTokenizer{T})(token::T) where T
        haskey(tokenizer.lookup, token) ? tokenizer.lookup[token] : tokenizer.unkidx
    end

    function (tokenizer::SequenceTokenizer)(idx::Integer)
        tokenizer.alphabet[idx]
    end

    function (tokenizer::SequenceTokenizer{T})(x::A) where {T, A <: AbstractArray}
        map(i -> tokenizer(i), x)
    end

    function (tokenizer::SequenceTokenizer{T})(batch::A) where {T, A <: AbstractVector{<:AbstractVector{T}}}
        lengths = map(length, batch)
        max_length = maximum(lengths)
        indices = fill(tokenizer.unkidx, max_length, length(batch))
        for j in eachindex(batch)
            local seq = batch[j]
            for i in eachindex(seq)
                @inbounds indices[i, j] = tokenizer(seq[i])
            end
        end
        indices
    end

    Functors.@functor SequenceTokenizer
    Optimisers.trainable(tokenizer::SequenceTokenizer) = (;)
end
