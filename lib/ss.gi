# vim: ft=gap sts=2 et sw=2

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
#   *stabgens:    A list whose i-th element is a list of generators for the
#                 i-th stabilizer group.
#   *orbits:      A list whose i-th element is a Schreier vector for the orbit of
#                 base[i] in G^(i) = stabilizers[i].
#   *orbitsizes:  A list whose i-th element is the number of elements in the orbit
#                 of base[i] in G^(i).
#
# The fields marked * are present only if has_chain = true; see the function 
# ComputeChainFromBSGS. This function does not compute the stabilizer chain --- 
# structures initialized here have has_chain = false. 
InstallGlobalFunction(BSGS, function (group, base, sgs)
  return rec(group := group, base := base, sgs := sgs, has_chain := false);
end);

# BSGSFromGAP(group)
# For testing purposes, initialises a BSGS structure using the GAP builtin
# functions.
InstallGlobalFunction(BSGSFromGAP, function (group)
  local sc;
  sc := StabChain(group);
  return BSGS(group, BaseStabChain(sc), StrongGeneratorsStabChain(sc));
end);

# BSGSFromGroup(group)
# Initialises a BSGS structure from an existing group's generating set, and
# compute a chain for it using the Schreier-Sims algorithm (see SchreierSims).
InstallGlobalFunction(BSGSFromGroup, function (group)
  local B;
  B := BSGS(group, [], ShallowCopy(GeneratorsOfGroup(group)));
  SchreierSims(B);
  return B;
end);

# SchreierSims(bsgs)
# Attempt to extend the given BSGS structure into a genuine base and strong
# generating set respectively for G using the Schreier–Sims algorithm.
InstallGlobalFunction(SchreierSims, function (bsgs)
  local i, added_generator, stripped, iterators, g, l;

  bsgs.sgs := List(bsgs.sgs);
  bsgs.stabgens := [];
  ExtendBaseIfStabilized(bsgs);
  ComputeChainForBSGS(bsgs);

  # So Strip() etc., don't interfere
  bsgs.has_chain := true;

  # The condition we need to verify for our structure to be a genuine BSGS is
  # that the stabiliser of the i-th base point in the i-th "stabiliser" is the
  # (i+1)-th stabiliser. We check this by checking the membership of each
  # generator of the stabiliser is there, a generating set being given by
  # Schreier's lemma (see SchreierGenerators).
  # This condition will be an invariant of this loop; it is true at the start
  # since by the time we are here, we know the (k+ 1)th stabiliser is trivial
  # (k being the size of the base). Since this holds, the StabilizerChainStrip
  # procedure can still be used to check membership in the (i+1)th group.
  i := Size(bsgs.base);

  iterators := [];
  while i >= 1 do
    Info(NewssInfo, 3, "Starting SS loop (index ", i, ")");
    added_generator := false;

    if not IsBound(iterators[i]) then
      iterators[i] := SchreierGenerators(bsgs, i);
    fi;

    for g in iterators[i] do
      if g = () then continue; fi;
      stripped := StabilizerChainStrip(bsgs, g);

      # If the stripped permutation is not the identity, it was not in the next
      # group --- so we adjoin it.
      if stripped.residue <> () then
        Info(NewssInfo, 3, "Adjoining generator ", g);

        # Additionally, if the strip procedure made it to the last iteration,
        # we know it fixes all the existing base points and that we need to
        # extend our basis again.
        if stripped.level > Size(bsgs.base) then
          ExtendBase(bsgs, stripped.residue);
        fi;

        for l in [i + 1 .. stripped.level] do
          Add(bsgs.stabgens[l], stripped.residue);
          Add(bsgs.sgs, stripped.residue);
          ComputeStabOrbForBSGS(bsgs, l);
          # We might be able to avoid this as well.
          iterators[l] := SchreierGenerators(bsgs, l);
        od;
        i := stripped.level;
        added_generator := true;
        break;
      fi;
    od;

    # If we didn't adjoin any more generators, they must all have been in the
    # group and we can move on to verify the condition for the next group.
    if not added_generator then
      i := i - 1;
    fi;
  od;

  # Once we finish the loop, we know we have a correct base, SGS and stabilizer chain.
  Info(NewssInfo, 2, "Computed stabiliser chain.");
  return bsgs;
end);

# EnsureBSGSChainComputed(bsgs)
# Given a BSGS structure, compute the basic stabilizers and basic orbits if
# they have not already been (see ComputeChainForBSGS). Returns nothing; the
# chain is stored in the BSGS structure (see the function BSGS).
InstallGlobalFunction(EnsureBSGSChainComputed, function (bsgs)
  if not bsgs.has_chain then
    ComputeChainForBSGS(bsgs);
    bsgs.has_chain := true;
  fi;
end);

# ComputeChainForBSGS(bsgs)
# Given a BSGS structure, compute the basic stabilizers (i.e. the stabilizer
# chain) and basic orbits. Returns nothing; the chain is stored in the BSGS
# structure (see the function BSGS).
InstallGlobalFunction(ComputeChainForBSGS, function (bsgs)
  local stabilizer, base_subset, i, gens;

  bsgs.stabgens := [bsgs.sgs];
  bsgs.stabilizers := [bsgs.group];
  bsgs.orbits := [];
  bsgs.orbitsizes := [];

  for i in [1 .. Size(bsgs.base)] do
    # The i-th stabilizer is generated by those generators in the SGS which fix
    # [b_1, ..., b_i], where b_k is the kth element of the base.
    base_subset := bsgs.base { [1 .. i - 1] };
    gens := Filtered(bsgs.sgs, g -> Stabilizes(g, base_subset));
    if Size(gens) = 0 then
      gens := [()];
    fi;
    bsgs.stabgens[i] := gens;

    ComputeStabOrbForBSGS(bsgs, i);
  od;
end);

# ComputeStabOrbForBSGS(bsgs, i)
# Given a BSGS structure, compute the basic stabilizer with the given
# generators and the corresponding basic orbit for the i-th stabilizer group.
InstallGlobalFunction(ComputeStabOrbForBSGS, function (bsgs, i)
  local base_subset, gens, orbstab, j;
  Info(NewssInfo, 3, "Computing staborb for ", bsgs, " index ", i);

  # We special case the first entry.
  if i = 1 then
    bsgs.stabgens[i] := bsgs.sgs;
    bsgs.stabilizers[i] := bsgs.group;
  else
    bsgs.stabilizers[i] := Group(bsgs.stabgens[i]);
  fi;

  # Then compute the orbit.
  orbstab := NOrbitStabilizer(bsgs.stabgens[i], bsgs.base[i], OnPoints, true);
  bsgs.orbits[i] := orbstab.sv;
  bsgs.orbitsizes[i] := Size(orbstab.orbit);

  # We want to compute the orbit with respect to the generators of the current
  # stabilizer. But we want the Schreier vector to be able to answer "not in
  # the orbit" for a point greater than the greatest it acts on. (i.e. 4 in
  # <(1,2,3)>). So pad the orbit with zeros in this case.
  # I think orbit lengths are generally reasonably small, but we could do this
  # with less storage if worthwhile.
  for j in [Size(bsgs.orbits[i]) + 1 .. LargestMovedPoint(bsgs.group)] do
    bsgs.orbits[i][j] := 0;
  od;
end);

# ExtendBaseIfStabilized(bsgs)
# Extends the base of a BSGS structure until no permutation in the SGS fixes
# all of the base points.
InstallGlobalFunction(ExtendBaseIfStabilized, function (bsgs)
  local s;

  for s in bsgs.sgs do
    if s <> () and Stabilizes(s, bsgs.base) then
      ExtendBase(bsgs, s);
    fi;
  od;
end);

# ExtendBase(bsgs, culprit)
# Extends the base of a BSGS structure to include a new point, given a
# permutation culprit which fixes all current base points.
InstallGlobalFunction(ExtendBase, function (bsgs, culprit)
  local x;
  # First, find an appropriate point to add (there must be one here)
  x := Difference(MovedPoints(culprit), bsgs.base)[1];
  Info(NewssInfo, 3, "Extending base to include ", x);
  # Then do the bookkeeping
  Add(bsgs.base, x);
  Add(bsgs.stabgens, []);
end);

# SchreierGenerators(bsgs, i)
# Returns an iterator the (possibly trivial) Schreier generators for the
# stabilizer of the i-th base point in the i-th stabilizer group in the given
# BSGS structure.
InstallGlobalFunction(SchreierGenerators, function (bsgs, i)
  # Take this out here so it has a name; it's easier to read the profiling
  # then.
  local SchreierGenerators_Next;
  SchreierGenerators_Next := function (iter)
    local x, u_beta_x, gen;

    if iter!.gen_iter = false or IsDoneIterator(iter!.gen_iter) then
      while not IsDoneIterator(iter!.orbit_iter) do
        iter!.orbit := NextIterator(iter!.orbit_iter);
        iter!.orbit_index := iter!.orbit_index + 1;
        if iter!.orbit <> 0 then
          break;
        fi;
      od;

      if IsDoneIterator(iter!.orbit_iter) then
        # Quite messy. Unfortunately checking for this case properly in
        # IsDoneIterator would get even messier.
        return ();
      fi;

      iter!.u_beta := SchreierVectorPermFromBasePoint(bsgs.stabgens[i],
                                                      bsgs.orbits[i],
                                                      iter!.orbit_index);
      iter!.gen_iter := Iterator(bsgs.stabgens[i]);
    fi;

    x := NextIterator(iter!.gen_iter);
    u_beta_x := SchreierVectorPermFromBasePoint(bsgs.stabgens[i],
                                                bsgs.orbits[i],
                                                iter!.orbit_index ^ iter!.u_beta);

    gen := iter!.u_beta * x * u_beta_x^(-1);
    Info(NewssInfo, 3, "Yielding Schreier gen. ", gen, " for stab ", i, " = <", bsgs.stabgens[i], ">");
    return gen;
  end;

  return IteratorByFunctions(rec(
    orbit_iter := Iterator(bsgs.orbits[i]),
    gen_iter := false,
    orbit_index := 0,
    orbit := 0,
    NextIterator := SchreierGenerators_Next,
    IsDoneIterator := function (iter)
      return IsDoneIterator(iter!.orbit_iter) and iter!.gen_iter <> false and
             IsDoneIterator(iter!.gen_iter);
    end,
    ShallowCopy := function (iter)
      return rec(
        orbit_iter := ShallowCopy(iter!.orbit_iter),
        gen_iter := ShallowCopy(iter!.gen_iter),
        orbit_index := iter!.orbit_index,
        orbit := iter!.orbit,
        NextIterator := iter!.NextIterator,
        IsDoneIterator := iter!.IsDoneIterator,
        ShallowCopy := iter!.ShallowCopy,
        PrintObj := iter!.PrintObj
      );
    end,
    PrintObj := function (iter)
      Print("<iterator over Schreier generators [group ", i, "]>");
    end));
end);


# StabilizerChainStrip(bsgs, g)
# Corresponds to the procedure Strip in §4.4.1 of Holt et al. or the builtin
# function SiftedPermutation. Here, bsgs is a BSGS structure for a group G and
# g is an element of Sym(\Omega), where G acts on \Omega. The result is a
# record containing the fields:
#   residue:    The permutation after the strip operation. This is () if and
#               only if g is truly an element of G.
#   level:      The iteration at which the stripping stopped.
InstallGlobalFunction(StabilizerChainStrip, function (bsgs, g)
  local h, i, beta, u;
  EnsureBSGSChainComputed(bsgs);
  h := g;

  for i in [1 .. Size(bsgs.base)] do
    beta := bsgs.base[i] ^ h;
    if bsgs.orbits[i][beta] = 0 then
      return rec(residue := h, level := i);
    fi;
    
    u := SchreierVectorPermFromBasePoint(bsgs.stabgens[i], bsgs.orbits[i], beta);
    h := h * u^(-1);
  od;

  return rec(residue := h, level := i + 1);
end);

# StabilizerChainContains(bsgs, g)
# Returns true if the permutation g is in the group described by the BSGS
# structure bsgs, otherwise returns false.
InstallGlobalFunction(StabilizerChainContains, function (bsgs, g)
  if LargestMovedPoint(g) > LargestMovedPoint(bsgs.sgs) then
    return false;
  else
    return StabilizerChainStrip(bsgs, g).residue = ();
  fi;
end);

# StabilizerChainOrder(bsgs)
# Return the order of the group described by the given BSGS structure.
InstallGlobalFunction(StabilizerChainOrder, function (bsgs)
  local order, U;
  EnsureBSGSChainComputed(bsgs);
  return Product(bsgs.orbitsizes);
end);

