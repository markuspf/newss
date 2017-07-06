# vim: ft=gap sts=2 et sw=2
Read("orbstab.g");

# BSGS(group, base, sgs)
# Initialize a BSGS structure for a group, given a base and strong generating
# set for it. A BSGS structure is a record containing the following fields:
#
#   group:        The group G for which base and sgs are a base and SGS,
#   sgs:          A strong generating set for G,
#   base:         A base for G relative to sgs,
#   has_chain:    true if a stabiliser chain has been computed yet for this base
#                 and SGS, otherwise false.
#   *stabilizers: The stabilizer chain corresponding to base and sgs, i.e. a
#                 sequence of subgroups [G^(1), G^(2), ..., G^(k+1)] where
#                     1 = G^(k+1) <= G^(k) <= ... <= G^(1) = G,
#                 with k being the size of sgs.
#   *orbits:      A list whose i-th element is a Schreier vector for the orbit of
#                 base[i] in G^(i) = stabilizers[i].
#
# The fields marked * are present only if has_chain = true; see the function
# ComputeChainFromBSGS. This function does not compute the stabilizer chain ---
# structures initialized here have has_chain = false.
BSGS := function (group, base, sgs)
  return rec(group := group, base := base, sgs := sgs, has_chain := false);
end;

# BSGSFromGAP(group)
# For testing purposes, initialises a BSGS structure using the GAP builtin
# functions.
BSGSFromGAP := function (group)
  local sc;
  sc := StabChain(group);
  return BSGS(group, BaseStabChain(sc), StrongGeneratorsStabChain(sc));
end;

# ComputeChainForBSGS(bsgs)
# Given a BSGS structure, compute the basic stabilizers (i.e. the stabilizer
# chain) and basic orbits. Returns nothing; the chain is stored in the BSGS
# structure (see the function BSGS).
ComputeChainForBSGS := function (bsgs)
  local stabilizer, base_subset, i, beta;

  # Don't do the work twice.
  if bsgs.has_chain then
    return bsgs;
  fi;

  bsgs.stabilizers := [bsgs.group];
  bsgs.orbits := [];

  for i in [2 .. Size(bsgs.base) + 1] do
    base_subset := bsgs.base{[1 .. i-1]};
    stabilizer := Intersection(List(base_subset, alpha -> NStabilizer(bsgs.sgs, alpha)));
    Add(bsgs.stabilizers, stabilizer);
  od;

  for beta in bsgs.base do
    Add(bsgs.orbits, NOrbitStabilizer(bsgs.sgs, beta, OnPoints, true).sv);
  od;

  bsgs.has_chain := true;
end;


# StabilizerChainStrip(bsgs, g)
# Corresponds to the procedure Strip in §4.4.1 of Holt et al or the builtin
# function SiftedPermutation. Here, bsgs is a BSGS structure for a group G and
# g is an element of G. The result is () if and only if the permutation g is in
# G.
StabilizerChainStrip := function (bsgs, g)
  local h, i, beta, u;
  ComputeChainForBSGS(bsgs);
  h := g;

  for i in [1 .. Size(bsgs.base)] do
    beta := bsgs.base[i] ^ h;
    if bsgs.orbits[i][beta] = 0 then
      return h;
    fi;
    
    u := SchreierVectorPermFromBasePoint(bsgs.sgs, bsgs.orbits[i], beta);
    h := h * u^(-1);
  od;

  return h;
end;

# StabilizerChainContains(bsgs, g)
# Returns true if the permutation g is in the group described by the BSGS
# structure bsgs, otherwise returns false.
StabilizerChainContains := function (bsgs, g)
  return StabilizerChainStrip(bsgs, g) = ();
end;

