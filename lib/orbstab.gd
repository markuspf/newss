# vim: ft=gap sts=2 et sw=2

#! @Chapter Orbits and Stabilizers

#! @Section Orbit/Stabilizer computation

#! @Arguments X_or_G, alpha, action, compute_sv
#! @Returns a record with the results of the orbit/stabilizer computation
#! @Description
#! Given a permutation group $G$ with generating set $X$ acting on $\Omega$
#! (by a function <C>action</C>), and an element <C>alpha</C> of $\Omega$,
#! compute a record with the following members:
#! * **orbit**: the orbit of alpha in $G$,
#! * **moves**: the element <C>moves[i]</C> is a permutation such that
#!              $$ \mathrm{moves}[i]^{\rm alpha} = O[i], $$
#! * **sv**: a Schreier vector for alpha in $G$ (if <C>compute_sv</C> is
#!           <K>true</K>),
#! * **stabilizer**:  the stabiliser of alpha in $G$.
#! This corresponds to the procedures OrbitStabilizer, OrbitSv in §4.1 of Holt,
#! et al. Note that this function can only compute the Schreier vector if
#! $\Omega$ is a set of natural numbers.
DeclareGlobalFunction("NOrbitStabilizer");

#! @Arguments g, O
#! @Returns a boolean
#! @Description
#! Suppose $G$ is a group acting on a set $\Omega$. Then given an element $g$
#! of $G$ and a subset $O$ of $\Omega$, determine whether $G$ fixes $O$
#! pointwise.
DeclareGlobalFunction("Stabilizes");


#! @Section Schreier vectors

#! @Arguments X, sv, beta
#! @Returns a permutation $u$ such $u^{\beta_i} = $<C> beta</C>
#! @Description
#! Given a permutation group $G$ with generating set $X$ acting on $\Omega$, a
#! Schreier vector <C>sv</C> for the orbit of an element $\alpha$ in $G$, and
#! another element <C>beta</C> in this orbit, returns a permutation $u$ such
#! that <C>alpha ^ u = beta</C>. If beta is not in the orbit, returns
#! <K>false</K>.
DeclareGlobalFunction("SchreierVectorPermFromBasePoint");

#! @Arguments X, sv, beta
#! @Returns a permutation word $u$ such that the successive image of $\beta_i$
#! under each permutation in $u$ is <C>beta</C>.
#! @Description
#! Given a permutation group $G$ with generating set $X$ acting on $\Omega$, a
#! Schreier vector <C>sv</C> for the orbit of an element $\alpha$ in $G$, and
#! another element <C>beta</C> in this orbit, returns a permutation word $u$ such
#! that the image of <C>alpha</C> under <C>u</C> is <C>beta</C> --- see section
#! <Ref Sect="Chapter_Miscellany_Section_Permutation_words"/> on permutation words.
#! If <C>beta</C> is not in the given orbit, return <K>false</K>.
DeclareGlobalFunction("SchreierVectorWordFromBasePoint");

#! @Arguments X, sv, beta
#! @Returns a permutation in $G_{\rm beta}$, where $G = \langle X \rangle$.
#! @Description
#! Given a Schreier vector <C>sv</C> for the orbit of <C>beta</C> under a group
#! $G$ return a random element of the subgroup of $G$ stabilizing <C>beta</C>.
#! The parameter <C>X</C> specifies the group $G$ as a list of generators,
#! as used to construct <C>sv</C>.
DeclareGlobalFunction("RandomStabilizerElement");

DeclareGlobalFunction("NEWSS_SchreierVector");
DeclareGlobalFunction("NEWSS_ExtendSchreierVector");
