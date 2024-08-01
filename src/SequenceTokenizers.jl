module SequenceTokenizers
    using Functors
    using Optimisers

    export SequenceTokenizer

    struct SequenceTokenizer{T, V <: AbstractVector{T}}
        alphabet::V
        lookup::Dict{T, Int32}
        unksym::T
        unkidx::Int32

        function SequenceTokenizer(alphabet::V, unksym::T) where {T, V <: AbstractVector{T}}
            if !(unksym in alphabet)
                alphabet = vcat(unksym, alphabet)
                unkidx = Int32(1)
            else
                unkidx = Int32(findfirst(isequal(unksym), alphabet))
            end
            lookup = Dict{T, Int32}(x => Int32(idx) for (idx, x) in enumerate(alphabet))
            new{T, V}(alphabet, lookup, unksym, unkidx)
        end
    end

    Base.length(tokenizer::SequenceTokenizer) = length(tokenizer.alphabet)

    Base.show(io::IO, tokenizer::SequenceTokenizer{T}) where T =
        print(io, "SequenceTokenizer{$T}(length(alphabet)=$(length(tokenizer)), unksym=$(tokenizer.unksym))")

    @inline (tokenizer::SequenceTokenizer{T})(token::T) where T =
        get(tokenizer.lookup, token, tokenizer.unkidx)

    @inline (tokenizer::SequenceTokenizer)(idx::Integer) = tokenizer.alphabet[idx]

    function (tokenizer::SequenceTokenizer{T})(x::AbstractArray) where T
        return map(tokenizer, x)
    end

    function (tokenizer::SequenceTokenizer{T})(batch::AbstractVector{<:AbstractVector{T}}) where T
        max_length = maximum(length, batch)
        indices = Matrix{Int32}(undef, max_length, length(batch))
        
        @inbounds for (j, seq) in enumerate(batch)
            for i in eachindex(seq)
                indices[i, j] = tokenizer(seq[i])
            end
            for i in (length(seq) + 1):max_length
                indices[i, j] = tokenizer.unkidx
            end
        end
        
        return indices
    end

    Functors.@functor SequenceTokenizer
    Optimisers.trainable(tokenizer::SequenceTokenizer) = NamedTuple()

end