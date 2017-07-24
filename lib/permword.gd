# vim: ft=gap sts=2 et sw=2

#! @Chapter Miscellany
#! @Section Permutation words
#!
#! A permutation word is simply a list of permutations which represents their
#! product, to avoid having to actually perform the multiplication. 
#!
#! <ManSection>
#! <Func Name="PermWordMul" Arg="word1, word2[, ...]"/>
#! <Returns>the product of the given permutation words</Returns>
#! </ManSection>

DeclareSynonym("PermWordMul", Concatenation);

#! @Arguments word
#! @Returns the multiplied-out permutation corresponding to the given
#! permutation word
DeclareGlobalFunction("PermWordAsPerm");

#! @Arguments pt, word
#! @Returns the image of <C>pt</C> under the permutation described by the
#! permutation word <C>word</C>
DeclareGlobalFunction("PermWordImage");

#! @Arguments word
#! @Returns the inverse of the given permutation word
DeclareGlobalFunction("PermWordInverse");

#! @Arguments word, pt
#! @Returns the preimage of the point <C>pt</C> under the permutation described
#! by <C>word</C>
#! @Description Note that the argument order is reversed from that of
#! <Ref Func="PermWordImage"/>, to mirror the GAP syntax <C>pt ^ perm</C> for
#! the image of a point, and <C>perm / pt</C> for the preimage.
DeclareGlobalFunction("PermWordPreImage");
