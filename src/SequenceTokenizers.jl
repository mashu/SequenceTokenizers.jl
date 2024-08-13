"""
    SequenceTokenizers

A module for tokenizing sequences of symbols into numerical indices and vice versa.
This module provides functionality for creating tokenizers, encoding sequences,
and working with one-hot representations of tokenized data.

# Exports
- `SequenceTokenizer`: A struct for tokenizing sequences
- `onehot_batch`: Convert tokenized sequences to one-hot representations
- `onecold_batch`: Convert one-hot representations back to tokenized sequences

# Example
```julia
using SequenceTokenizers

# Create a tokenizer for DNA sequences
dna_alphabet = ['A', 'C', 'G', 'T']
tokenizer = SequenceTokenizer(dna_alphabet, 'N')

# Tokenize a sequence
seq = "ACGTACGT"
tokenized = tokenizer(seq)

# Convert to one-hot representation
onehot = onehot_batch(tokenizer, tokenized)

# Convert back to tokens
recovered = onecold_batch(tokenizer, onehot)
```
"""
module SequenceTokenizers
    using OneHotArrays

    export SequenceTokenizer, onehot_batch, onecold_batch, AbstractSequenceTokenizer

    abstract type AbstractSequenceTokenizer end

    """
        SequenceTokenizer{T, V <: AbstractVector{T}}

    A struct for tokenizing sequences of symbols into numerical indices.

    # Fields
    - `alphabet::V`: The set of valid symbols in the sequences
    - `lookup::Vector{UInt32}`: A lookup table for fast symbol-to-index conversion
    - `unksym::T`: The symbol to use for unknown tokens
    - `unkidx::UInt32`: The index assigned to the unknown symbol

    # Example
    ```julia
    alphabet = ['a', 'b', 'c']
    tokenizer = SequenceTokenizer(alphabet, 'x')
    ```
    """
    struct SequenceTokenizer{T, V <: AbstractVector{T}} <: AbstractSequenceTokenizer
        alphabet::V
        lookup::Vector{UInt32}
        unksym::T
        unkidx::UInt32

        """
            SequenceTokenizer(alphabet::V, unksym::T) where {T, V <: AbstractVector{T}}

        Construct a SequenceTokenizer with the given alphabet and unknown symbol.

        # Arguments
        - `alphabet::V`: A vector of symbols representing the tokenizer's alphabet
        - `unksym::T`: The symbol to use for unknown tokens

        # Returns
        A new `SequenceTokenizer` instance

        # Example
        ```julia
        alphabet = ['a', 'b', 'c']
        tokenizer = SequenceTokenizer(alphabet, 'x')
        ```
        """
        function SequenceTokenizer(alphabet::V, unksym::T) where {T, V <: AbstractVector{T}}
            lookup = fill(UInt32(0), 256)  # Covers all ASCII characters

            if !(unksym in alphabet)
                alphabet = vcat(unksym, alphabet)
                unkidx = UInt32(1)
            else
                unkidx = UInt32(findfirst(isequal(unksym), alphabet))
            end

            for (idx, char) in enumerate(alphabet)
                if codepoint(char) <= length(lookup)
                    lookup[codepoint(char)] = UInt32(idx)
                end
            end

            new{T, V}(alphabet, lookup, unksym, unkidx)
        end
    end

    """
        Base.length(tokenizer::AbstractSequenceTokenizer)

    Get the number of unique tokens in the tokenizer's alphabet.

    # Returns
    The length of the tokenizer's alphabet

    # Example
    ```julia
    alphabet = ['a', 'b', 'c']
    tokenizer = SequenceTokenizer(alphabet, 'x')
    println(length(tokenizer))  # Output: 4
    ```
    """
    Base.length(tokenizer::AbstractSequenceTokenizer) = length(tokenizer.alphabet)

    """
        Base.show(io::IO, tokenizer::SequenceTokenizer{T}) where T

    Custom display method for SequenceTokenizer instances.

    # Example
    ```julia
    alphabet = ['a', 'b', 'c']
    tokenizer = SequenceTokenizer(alphabet, 'x')
    println(tokenizer)  # Output: SequenceTokenizer{Char}(length(alphabet)=4, unksym=x)
    ```
    """
    Base.show(io::IO, tokenizer::SequenceTokenizer{T}) where T =
        print(io, "SequenceTokenizer{$T}(length(alphabet)=$(length(tokenizer)), unksym=$(tokenizer.unksym))")

    """
        (tokenizer::SequenceTokenizer{T})(token::T) where T

    Convert a single token to its corresponding index.

    # Arguments
    - `token::T`: A single token to be converted to an index

    # Returns
    The index of the token in the tokenizer's alphabet, or the unknown token index if not found

    # Example
    ```julia
    alphabet = ['a', 'b', 'c']
    tokenizer = SequenceTokenizer(alphabet, 'x')
    println(tokenizer('a'))  # Output: 2
    println(tokenizer('x'))  # Output: 1
    println(tokenizer('z'))  # Output: 1 (unknown token)
    ```
    """
    @inline function (tokenizer::SequenceTokenizer{T})(token::T) where T
        code = codepoint(token)
        if code <= length(tokenizer.lookup)
            idx = tokenizer.lookup[code]
            return idx == 0 ? tokenizer.unkidx : idx
        else
            return tokenizer.unkidx
        end
    end

    """
        (tokenizer::SequenceTokenizer)(idx::Integer)

    Convert an index back to its corresponding token.

    # Arguments
    - `idx::Integer`: An index to be converted back to a token

    # Returns
    The token corresponding to the given index in the tokenizer's alphabet

    # Example
    ```julia
    alphabet = ['a', 'b', 'c']
    tokenizer = SequenceTokenizer(alphabet, 'x')
    println(tokenizer(2))  # Output: 'a'
    println(tokenizer(1))  # Output: 'x' (unknown token)
    ```
    """
    @inline (tokenizer::SequenceTokenizer)(idx::Integer) = tokenizer.alphabet[idx]

    """
        (tokenizer::SequenceTokenizer{T})(input::AbstractString) where T

    Tokenize a string input using the SequenceTokenizer.

    This method efficiently converts the input string to a vector of tokens of type T
    and applies the tokenizer to each element.

    # Arguments
    - `tokenizer::SequenceTokenizer{T}`: The tokenizer to use
    - `input::AbstractString`: The input string to be tokenized

    # Returns
    A Vector{UInt32} of token indices corresponding to the characters in the input string

    # Performance Notes
    - This method uses `collect(T, input)` to convert the string to a vector of type T
    - It's marked as `@inline` for potential performance benefits in certain contexts

    # Example
    ```julia
    alphabet = ['a', 'b', 'c']
    tokenizer = SequenceTokenizer(alphabet, 'x')
    result = tokenizer("abcx")
    println(result)  # Output: [2, 3, 4, 1]
    ```
    """
    @inline function (tokenizer::SequenceTokenizer{T})(input::AbstractString) where T
        return tokenizer(collect(T, input))
    end

    """
        (tokenizer::SequenceTokenizer{T})(batch::AbstractVector{<:AbstractString}) where T

    Tokenize a batch of string sequences, padding shorter sequences with the unknown token.

    # Arguments
    - `tokenizer::SequenceTokenizer{T}`: The tokenizer to use
    - `batch::AbstractVector{<:AbstractString}`: A vector of string sequences to be tokenized

    # Returns
    A matrix of indices, where each column represents a tokenized and padded sequence

    # Example
    ```julia
    tokenizer = SequenceTokenizer(['A','T','G','C'], 'N')
    sequences = ["ATG", "ATGCGC"]
    result = tokenizer(sequences)
    ```
    """
    @inline function (tokenizer::SequenceTokenizer{T})(batch::AbstractVector{<:AbstractString}) where T
        return tokenizer(collect.(T, batch))
    end

    """
        (tokenizer::SequenceTokenizer{T})(x::AbstractArray) where T

    Tokenize an array of symbols.

    # Arguments
    - `x::AbstractArray`: An array of symbols to be tokenized

    # Returns
    An array of indices corresponding to the input symbols

    # Example
    ```julia
    alphabet = ['a', 'b', 'c']
    tokenizer = SequenceTokenizer(alphabet, 'x')
    println(tokenizer(['a', 'b', 'z', 'c']))  # Output: [2, 3, 1, 4]
    ```
    """
    function (tokenizer::SequenceTokenizer{T})(x::AbstractArray) where T
        return map(tokenizer, x)
    end

    """
        (tokenizer::SequenceTokenizer{T})(batch::AbstractVector{<:AbstractVector{T}}) where T

    Tokenize a batch of sequences, padding shorter sequences with the unknown token.

    # Arguments
    - `batch::AbstractVector{<:AbstractVector{T}}`: A vector of sequences to be tokenized

    # Returns
    A matrix of indices, where each column represents a tokenized and padded sequence

    # Example
    ```julia
    alphabet = ['a', 'b', 'c']
    tokenizer = SequenceTokenizer(alphabet, 'x')
    sequences = [['a', 'b'], ['c', 'a', 'b']]
    println(tokenizer(sequences))
    # Output:
    # [2 4
    #  3 2
    #  1 3]
    ```
    """
    function (tokenizer::SequenceTokenizer{T})(batch::AbstractVector{<:AbstractVector{T}}) where T
        max_length = maximum(length, batch)
        indices = Matrix{UInt32}(undef, max_length, length(batch))
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

    """
        onehot_batch(tokenizer::SequenceTokenizer, batch::AbstractMatrix{UInt32})

    Convert a batch of tokenized sequences to one-hot representations.

    # Arguments
    - `tokenizer::SequenceTokenizer`: The tokenizer used for the sequences
    - `batch::AbstractMatrix{UInt32}`: A matrix of tokenized sequences

    # Returns
    A OneHotArray representing the one-hot encoding of the input batch

    # Example
    ```julia
    alphabet = ['a', 'b', 'c']
    tokenizer = SequenceTokenizer(alphabet, 'x')
    sequences = [["a", "b"], ["c", "a", "b"]]
    tokenized = tokenizer(sequences)
    onehot = onehot_batch(tokenizer, tokenized)
    println(size(onehot))  # Output: (4, 3, 2)
    ```
    """
    function onehot_batch(tokenizer::AbstractSequenceTokenizer, batch::AbstractMatrix{UInt32})
        return Float32.(OneHotArray(batch, length(tokenizer)))
    end

    """
        onehot_batch(tokenizer::AbstractSequenceTokenizer, batch::AbstractVector{UInt32})

    Convert a batch of tokenized sequences to one-hot representations.

    This function takes a vector of token indices and converts it into a one-hot encoded
    representation using the alphabet of the provided tokenizer.

    # Arguments
    - `tokenizer::AbstractSequenceTokenizer`: The tokenizer used for the sequences. Its length
    determines the size of the one-hot encoding dimension.
    - `batch::AbstractVector{UInt32}`: A vector of token indices to be converted to
    one-hot representation.

    # Returns
    - `OneHotArray`: A one-hot encoded representation of the input batch. The resulting
    array will have dimensions (length(tokenizer), length(batch)).

    # Example
    ```julia
    alphabet = ['a', 'b', 'c']
    tokenizer = SequenceTokenizer(alphabet, 'x')
    tokenized_sequence = [2, 3, 1, 4]  # Corresponds to ['a', 'b', 'x', 'c']
    onehot = onehot_batch(tokenizer, tokenized_sequence)
    println(size(onehot))  # Output: (4, 4)
    println(onehot[:, 1])  # Output: [0, 1, 0, 0]
    ```

    # Note
    This function assumes that all indices in the input batch are valid for the
    tokenizer's alphabet. Indices outside the valid range may result in errors or
    unexpected behavior.

    # See also
    - [`SequenceTokenizer`](@ref): The tokenizer struct used to create the input batch.
    - [`onecold_batch`](@ref): The inverse operation, converting one-hot representations
    back to token indices.
    """
    function onehot_batch(tokenizer::AbstractSequenceTokenizer, batch::AbstractVector{UInt32})
        return Float32.(OneHotArray(batch, length(tokenizer)))
    end

    """
        onecold_batch(tokenizer::AbstractSequenceTokenizer, onehot_batch::OneHotArray)

    Convert a one-hot representation back to tokenized sequences.

    # Arguments
    - `tokenizer::AbstractSequenceTokenizer`: The tokenizer used for the sequences
    - `onehot_batch::OneHotArray`: A OneHotArray representing the one-hot encoding of sequences

    # Returns
    A matrix of indices representing the tokenized sequences

    # Example
    ```julia
    alphabet = ['a', 'b', 'c']
    tokenizer = SequenceTokenizer(alphabet, 'x')
    sequences = [['a', 'b'], ['c', 'a', 'b']]
    tokenized = tokenizer(sequences)
    onehot = onehot_batch(tokenizer, tokenized)
    recovered = onecold_batch(tokenizer, onehot)
    # Recovered result is batched therefore it remains padded
    println(recovered == ['a' 'c'; 'b' 'a'; 'x' 'b']) # Output: true
    ```
    """
    function onecold_batch(tokenizer::AbstractSequenceTokenizer, onehot_batch::AbstractArray)
        return onecold(onehot_batch, tokenizer.alphabet)
    end

end