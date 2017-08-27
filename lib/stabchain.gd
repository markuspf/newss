# vim: ft=gap sts=2 et sw=2
#! @Chapter Stabilizer Chains

DeclareCategory("IsBSGS", IsObject);
DeclareRepresentation("IsBSGSRep", IsNonAtomicComponentObjectRep, [
  "group",
  "base",
  "sgs",
  "initial_gens",
  "chain",
  "options",
  "tree"
]);
BindGlobal("BSGSFamily", NewFamily("BSGSFamily"));
BindGlobal("BSGSType", NewType(BSGSFamily, IsBSGS and IsBSGSRep and IsMutable));

#! @Section Creating stabilizer chains

#! @Arguments group, base, sgs
#! @Returns an initialized BSGS structure
#! @Description
#! Initialize a BSGS structure for a group, given a base and strong generating
#! set for it. A BSGS structure is an object containing the following components:
#!
#! * **group**:        The group $G$ for which <C>base</C> and <C>sgs</C> are a
#!                     base and SGS,
#! * **options**:      If a stabilizer chain was computed for this BSGS using
#!                     <Ref Func="BSGSFromGroup"/>, then this field contains
#!                     the final set of options used in the computation; see
#!                     <Ref Sect="Chapter_Stabilizer_Chains_Section_Options_for_stabilizer_chain_creation"/>,
#! * **sgs**:          A strong generating set for $G$ relative to <C>base</C>,
#! * **base**:         A base for $G$,
#! * **chain**:        A list of <C>newss</C> stabilizer chain records
#!                     corresponding to a stabilizer chain with respect to base
#!                     and sgs, i.e. a sequence of subgroups $[G^{(1)},
#!                     G^{(2)}, ..., G^{(k)}]$ where
#!                        $$1 \le G^{(k)} \le \cdots \le G^{(1)} = G,$$
#!                     with $k$ being the size of <C>sgs</C>. Each group
#!                     $G^{(i)}$ is generated by a subset of <C>sgs</C>, and
#!                     stabilizes the points $\beta_1, \beta_2, \ldots,
#!                     \beta_{i-1}$.
#! * **tree**:         A record containing the prefix tree used to cache
#!                     stabilizer chains computed for the same group. This
#!                     tree could be shared between many BSGS structures. The
#!                     precise layout of this structure is not part of the
#!                     public interface for the package, but be aware that it is
#!                     cyclic (i.e. it contains self-references).
#!
#! These can be accessed using the accessor function in
#! <Ref Sect="Chapter_Stabilizer_Chains_Section_Retrieving_data_from_chains"/>.
#! The chain field may not always be present; it must be computed with either the
#! <Ref Func="BSGSFromGroup" /> or (for testing purposes) the <Ref Func="BSGSFromGAP"/>
#! function.
#!
#! If present, the $i$-th element of <C>chain</C> is a stabilizer chain record,
#! containing the following fields describing the group $G^{(i)}$:
#! * **group**:     The group $G^{(i)}$, as a &GAP; group object.
#! * **gens**:      A list of generators for the group $G^{(i)}$.
#! * **orbit**:     A list whose $i$-th element is a Schreier vector record
#!                  describing the orbit of <C>base[i]</C> under
#!                  <C>stabgens[i]</C> --- see section
#!                  <Ref Sect="Chapter_Orbits_and_Stabilizers_Section_Schreier_vectors"/>.
#!
DeclareGlobalFunction("BSGS");

#! @Arguments bsgs
#! @Returns a BSGS structure with full stabilizer chain
#! @Description
#! For testing purposes, initialises a BSGS structure with stabilizer chain
#! using the &GAP; builtin functions.
DeclareGlobalFunction("BSGSFromGAP");

#! @Arguments group[, options]
#! @Returns a BSGS structure with full stabilizer chain
#! @Description
#! Initialises a BSGS structure from an existing group's generating set, and
#! compute a chain for it using the Schreier-Sims algorithm (see 
#! <Ref Func="SchreierSims"/>). For more information on the options which can
#! be passed in, see the section
#! <Ref Sect="Chapter_Stabilizer_Chains_Section_Options_for_stabilizer_chain_creation"/>.
DeclareGlobalFunction("BSGSFromGroup");

#! @Arguments bsgs
#! @Returns a GAP stabilizer chain structure
#! @Description
#! Takes a BSGS structure and, finding a base and strong generating set if
#! necessary (using the algorithms in this package), returns a &GAP; stabilizer
#! chain record representing the computed chain. (For testing purposes, the
#! topmost stabilizer chain record has an additional component
#! <C>from_newss := true</C>.)
DeclareGlobalFunction("GAPStabChainFromBSGS");

#! @Description
#! Overrides the default &GAP; stabilizer chain methods with the ones from this
#! package.
DeclareGlobalFunction("EnableNewssOverloads");


#! @Section Retrieving data from chains

#! @Arguments bsgs
#! @Returns the group $G$ that <A>bsgs</A> describes a stabilizer chain for
DeclareOperation("GroupBSGS", [IsBSGS]);
#! @Arguments bsgs
#! @Returns the set of strong generators for $G$ with respect to the base in <A>bsgs</A>
DeclareOperation("StrongGeneratorsBSGS", [IsBSGS]);
#! @Arguments bsgs
#! @Returns the base of <A>bsgs</A>
DeclareOperation("BaseBSGS", [IsBSGS]);
#! @Arguments bsgs
#! @Returns a list of stabilizer chain records for <A>bsgs</A>, if any have been computed
DeclareOperation("StabilizersBSGS", [IsBSGS]);
#! @Arguments bsgs, i
#! @Returns a stabilizer chain record for the <A>i</A>th stabilizer subgroup
DeclareOperation("StabilizerBSGS", [IsBSGS, IsInt]);

#! @Section Manipulating stabilizer chains

#! @Arguments bsgs, new_base
#! @Returns a BSGS structure for the same group as <A>bsgs</A>, but with base
#! <A>new_base</A>
#! @Description
#! Finds a stabilizer chain for the group described by <A>bsgs</A> with the
#! given base, either by starting with a copy of <A>bsgs</A> and performing a
#! change of base operation, or by retrieving a previously-calculated structure.
DeclareGlobalFunction("BSGSWithBase");

#! @Arguments bsgs, prefix
#! @Returns a BSGS structure for the same group as <A>bsgs</A>, whose base
#! has initial segment <A>prefix</A>
#! @Description
#! Finds a stabilizer chain for the group described by <A>bsgs</A> whose base
#! starts with the points <A>prefix</A>, either by computing a new chain using
#! a known-base version of the Schreier-Sims algorithm, or by retrieving a
#! suitable previously-calculated structure.
DeclareGlobalFunction("BSGSWithBasePrefix");

#! @Arguments bsgs, new_base
#! @Returns nothing
#! @Description
#! Modifies the given BSGS so that it contains a strong generating set and
#! stabilizer chain relative to the base <C>new_base</C>. This function does not
#! attempt to verify that <C>new_base</C> is in fact a base for the group.
DeclareGlobalFunction("ChangeBaseOfBSGS");

#! @Arguments bsgs
#! @Returns nothing
#! @Description
#! Given a BSGS structure, compute the basic stabilizers (i.e. the stabilizer
#! chain) and basic orbits. Returns nothing; the chain is stored in the BSGS
#! structure (see the function <Ref Func="BSGS"/>).
DeclareGlobalFunction("ComputeChainForBSGS");

#! @Arguments bsgs, g
#! @Returns a new BSGS structure
#! @Description
#! Returns the result of conjugating the stabilizer chain <A>bsgs</A> for a
#! group $G$ by the permutation <A>g</A>, such that its base $[\beta_1, \ldots,
#! \beta_n]$ is now $[\beta_1^g, \ldots, \beta_n^g]$, and we have a stabilizer
#! chain for $G^g$.
DeclareGlobalFunction("ConjugateBSGS");

#! @Arguments bsgs
#! @Returns a new BSGS structure
#! @Description
#! Creates a deep copy of the given BSGS structure.
DeclareGlobalFunction("CopyBSGS");

#! @Arguments bsgs, keep_initial_gens
#! @Returns a BSGS structure
#! @Description
#! Attempts to remove redundant generators from the given BSGS structure with
#! stabilizer chain, to produce a smaller strong generating set. If the
#! <C>keep_initial_gens</C> parameter is <K>true</K>, then do not attempt to
#! remove any generator in the BSGS structure's <C>initial_gens</C> set (see
#! <Ref Func="BSGS"/>).
DeclareGlobalFunction("RemoveRedundantGenerators");


DeclareGlobalFunction("NEWSS_AppendEmptyChain");
DeclareGlobalFunction("NEWSS_ChangeBaseByPointSwap");
DeclareGlobalFunction("NEWSS_ChangeBaseByRecomputing");
DeclareGlobalFunction("NEWSS_InsertRedundantBasePoint");
DeclareGlobalFunction("NEWSS_AppendTrivialBasePoint");
DeclareGlobalFunction("NEWSS_PerformBaseSwap");
