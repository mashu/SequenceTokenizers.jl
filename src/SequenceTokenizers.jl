module SequenceTokenizers
    using OneHotArrays

    export SequenceTokenizer, onehot_batch, onecold_batch

    struct SequenceTokenizer{T, V <: AbstractVector{T}}
        alphabet::V
        lookup::Vector{Int32}
        unksym::T
        unkidx::Int32

        function SequenceTokenizer(alphabet::V, unksym::T) where {T, V <: AbstractVector{T}}
            max_char_code = maximum(codepoint, alphabet)
            lookup = fill(Int32(0), max_char_code)

            if !(unksym in alphabet)
                alphabet = vcat(unksym, alphabet)
                unkidx = Int32(1)
            else
                unkidx = Int32(findfirst(isequal(unksym), alphabet))
            end

            for (idx, char) in enumerate(alphabet)
                lookup[codepoint(char)] = Int32(idx)
            end

            new{T, V}(alphabet, lookup, unksym, unkidx)
        end
    end

    Base.length(tokenizer::SequenceTokenizer) = length(tokenizer.alphabet)

    Base.show(io::IO, tokenizer::SequenceTokenizer{T}) where T =
        print(io, "SequenceTokenizer{$T}(length(alphabet)=$(length(tokenizer)), unksym=$(tokenizer.unksym))")

    @inline function (tokenizer::SequenceTokenizer{T})(token::T) where T
        code = codepoint(token)
        if code <= length(tokenizer.lookup)
            idx = tokenizer.lookup[code]
            return idx == 0 ? tokenizer.unkidx : idx
        else
            return tokenizer.unkidx
        end
    end

    @inline (tokenizer::SequenceTokenizer)(idx::Integer) = tokenizer.alphabet[idx]

    function (tokenizer::SequenceTokenizer{T})(x::AbstractArray) where T
        return map(tokenizer, x)
    end

    function (tokenizer::SequenceTokenizer{T})(batch::AbstractVector{<:AbstractVector{T}}) where T
        max_length = maximum(length, batch)
        indices = Matrix{Int32}(undef, max_length, length(batch))
        unkidx = tokenizer.unkidx
        
        @inbounds for (j, seq) in enumerate(batch)
            i = 1
            for token in seq
                indices[i, j] = tokenizer(token)
                i += 1
            end
            @simd for i′ in i:max_length
                indices[i′, j] = unkidx
            end
        end

        return indices
    end

    function onehot_batch(tokenizer::SequenceTokenizer, batch::AbstractMatrix{Int32})
        return OneHotArray(batch, length(tokenizer))
    end

    function onecold_batch(tokenizer::SequenceTokenizer, onehot_batch::OneHotArray)
        return onecold(onehot_batch, tokenizer.alphabet)
    end

end