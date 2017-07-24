# vim: ft=gap sts=2 et sw=2
## tests.g
## Various tests for the stabiliser chain algorithms in the package.
## To run them all, read this file and execute DoAllTests().

# The tests themselves

# VerifySCOrder(G)
# Check the order we compute for a group versus that computed by GAP.
VerifySCOrder := function(G)
  return Order(G.group) = StabilizerChainOrder(G);
end;

# VerifySCContains(G, H)
# Given a group H which is a subset of G, check that every element of G is
# correctly determined to be inside or outside H by the StabilizerChainContains
# function.
VerifySCContains := function (G, H_sc)
  local H, actually_in_H, think_in_H, x;
  H := H_sc.group;

  for x in G do
    actually_in_H := x in H;
    think_in_H := StabilizerChainContains(H_sc, x);
    if actually_in_H <> think_in_H then
      Print(x, " in H = ", actually_in_H, " but we thought ", think_in_H, ".\n");
      return false;
    fi;
  od;

  return true;

end;

# NUM_RANDOM_TEST_ELTS
# An integer specifying how many random elements to pick from a large ambient
# group to be tested with VerifyContainsPG.
NUM_RANDOM_TEST_ELTS := 2^16;

# VerifyContainsPG(G)
# Run VerifySCContains on lots of elements inside and outside a given group G.
VerifyContainsPG := function (G_sc)
  local deg, Sn, X, G;
  G := G_sc.group;
  deg := LargestMovedPoint(GeneratorsOfGroup(G));
  Sn := SymmetricGroup(deg);

  # For groups sitting in big S_n, it is not feasible to check all the points.
  # So pick lots of random ones instead.
  if deg <= 9 then
    return VerifySCContains(Sn, G_sc);
  else
    X := List([1 .. NUM_RANDOM_TEST_ELTS], i -> PseudoRandom(Sn));
    return VerifySCContains(X, G_sc);
  fi;
end;


# The groups to test.
GROUPS := [
  ["A_4", AlternatingGroup(4)],
  ["HCGT ex 4.1", Group([(1,3,7)(2,5), (3,4,6,7)])],
  ["Mathieu deg. 9", MathieuGroup(9)],
  ["S11", SymmetricGroup(11)],
  ["PrimitiveGroup(1024, 2)", PrimitiveGroup(1024, 2)],
  ["Suzuki", AtlasGroup("Suz")],
  ["[2^4]S(5)", TransitiveGroup(10,37)]
];

PickGroupOfDegree := function (degree)
  local counts, sources, first_type, type, count, index, group;
  counts := [NrPrimitiveGroups, NrTransitiveGroups];
  sources := [PrimitiveGroup, TransitiveGroup];

  first_type := PseudoRandom([1 .. Size(sources)]);
  type := first_type;
  count := counts[type](degree);
  repeat
    if count > 0 and count <> fail then
      index := PseudoRandom([1 .. count]);
      group := sources[type](degree, index);
      if HasName(group) then
        if StartsWith(Name(group), "S(") or
           StartsWith(Name(group), "A(") or
           StartsWith(Name(group), "Sym(") then
          return fail;
        fi;
        return [Name(group), group];
      else
        return [Concatenation(NameFunction(sources[type]),
                              "(", String(degree), ", ",
                              String(index), ")"), group];
      fi;
    fi;
    type := ((type + 1) mod Size(sources)) + 1;
  until type = first_type;

  return fail;
end;

PickSomeGroups := function (nr)
  local bounds, i, j, degree, group;
  bounds := [768, 30];
  i := 1;

  while i <= nr do
    j := PseudoRandom([1 .. Size(bounds)]);
    degree := PseudoRandom([1 .. bounds[j]]);
    group := PickGroupOfDegree(degree);
    if group <> fail then
      Add(GROUPS, group);
      i := i + 1;
    fi;

    if i mod 25 = 0 then
      Print("found ", i, " groups so far.\n");
    fi;
  od;
end;

PickGroupsByDegree := function (max_degree, per_degree)
  local g, degree, i;
  for degree in [2 .. max_degree] do
    for i in [1 .. per_degree] do
      g := PickGroupOfDegree(degree);
      if g <> fail then
        Add(GROUPS, [Name(g), g]);
      fi;
    od;
  od;
end;

# The test harness functions.
DoTest := function (name, fn, arg)
  local t, result;

  t := Runtime();
  result := fn(arg);
  t := Runtime() - t;

  Print(name, ": ");
  if result then
    Print("ok.\n");
  else
    Print("fail.\n");
  fi;
  
  return rec(group := name,
             group_degree := NrMovedPoints(arg.group),
             test := NameFunction(fn),
             success := result,
             time := t);
end;

RESULTS_FILENAME := "tests.csv";

DoTests := function (tests, constructor)
  local test, group, add, stabchains, i, results, t;

  results := [];

  Print("Computing stabilizer chains [", NameFunction(constructor), "]:\n");
  add := function (L, x) Add(L, x); return true; end;
  stabchains := [];
  for group in GROUPS do
    Print(group[1]);
    t := Runtime();
    Add(stabchains, constructor(group[2]));
    Add(results, rec(group := group[1],
                     group_degree := NrMovedPoints(group[2]),
                     group_order := 0,
                     test := NameFunction(constructor),
                     success := true,
                     time := Runtime() - t));
    Print("\n");
  od;
  Print("\n");

  for test in tests do
    Print(NameFunction(test), ":\n");
    for i in [1 .. Size(GROUPS)] do
      Add(results, DoTest(GROUPS[i][1], test, stabchains[i]));
    od;
    Print("\n");
  od;

  PrintCSV(RESULTS_FILENAME, results);
end;

LoadAtlasGroups := function ()
  local handle, str, G;
  handle := InputTextFile("atlasnames.txt");

  while true do
    str := Chomp(ReadLine(handle));
    if str <> fail and str <> "" then
      Print("Loading ", str, "\n");
      G := AtlasGroup(str);
      if IsPermGroup(G) then
        Add(GROUPS, [str, AtlasGroup(str)]);
      else
        Print("(skipping)\n");
      fi;
    else
      break;
    fi;
  od;
  CloseStream(handle);
end;

GAPShowdown := function (filename)
  local results, t, our_stabchain, our_time, gap_stabchain, gap_time, size, which, group, G;
  results := [];

  for group in GROUPS do
    Print(group[1], "\n");

    G := Group(GeneratorsOfGroup(group[2]));
    SetSize(G, Size(group[2]));

    t := Runtime();
    our_stabchain := BSGSFromGroup(G);
    our_time := Runtime() - t;

    t := Runtime();
    gap_stabchain := StabChain(G);
    gap_time := Runtime() - t;

    Add(results, rec(degree := NrMovedPoints(group[2]),
                     gap_time := gap_time,
                     our_time := our_time,
                     size := Size(group[2]),
                     which := group[1]));
  od;

  PrintCSV(filename, results);
end;


TESTS := [VerifyContainsPG, VerifySCOrder];
DoAllTests := function ()
  DoTests(TESTS, BSGSFromGroup);
end;
