% -------------------- PARSOVANI ---------------------

% Parser bilich znaku
pWhite      -->
    [] 
|   [Char], { char_type(Char, white) }, pWhite.

% Parser integeru ze cviceni
pInt(V)     -->
    [Digit],
    { atom_number(Digit, AtomDigit) },
    pInt2(V, AtomDigit).

pInt2(A, A) --> [].
pInt2(V, A) -->
    [Digit],
    { 
        atom_number(Digit, AtomDigit),
        A1 is A * 10 + AtomDigit
    },
    pInt2(V, A1).

% Parser pro vynechani koeficientu
pSkip(V)    --> pInt(V).
pSkip(1)    --> [].

% Parser integeru s optional minusem
pSigned(V)  -->
    pSkip(V)
|   ['-'], pSkip(V2), {V is -V2}.

% Parser pro C s exponentem (C^I), specialni pripad pro nultou a prvni mocninu
pExp(_, 0)  --> [].
pExp(C, 1)  --> [C], pWhite.
pExp(C, I)  --> [C], pWhite, ['^'], pWhite, pInt(I).

% Parser clenu tvaru Ka^Ib^j nebo Kb^Ja^I
pTerm(term(K, I, J))    -->
    pSigned(K), pWhite, pExp('a', I), pWhite, pExp('b', J), pWhite
|   pSigned(K), pWhite, pExp('b', J), pWhite, pExp('a', I), pWhite.

% Parser znamenka
pSign(plus)     --> ['+'].
pSign(minus)    --> ['-'].

% Prida znamenko k clenu
addSign(Term, plus, Term).
addSign(term(K, I, J), minus, term(K2, I, J)) :- K2 is -K.

% Naparsuje nekolik clenu mezi kterymi jsou znamenka
pTerms([Term], LastSign)          -->
    pWhite, pTerm(Term2), pWhite, {addSign(Term2, LastSign, Term)}.
pTerms([Term | Terms], LastSign)  -->
    pWhite, pTerm(Term2), pWhite, {addSign(Term2, LastSign, Term)}, pSign(Sign), pWhite, pTerms(Terms, Sign), pWhite.

% Rozdeli string na chary a zavola parser
parseTerms(String, Terms) :- string_chars(String, Chars), once(pTerms(Terms, plus, Chars, [])).


% -------------------- Hledani AG ---------------------


% Najde kladne cislo, vrati jeho index, hodnotu, zbytek pole
findPos([_ | Xs], Index, XIndex, XValue, Rest, EndIndex) :-
    NextIndex is Index + 1,
    findPos(Xs, NextIndex, XIndex, XValue, Rest, EndIndex).
findPos([X | Xs], Index, Index, X, Xs, NextIndex) :-
    NextIndex is Index + 1,
    X > 0.

% Najde zaporne cislo, vrati jeho index, hodnotu, zbytek pole
findNeg([_ | Xs], Index, XIndex, XValue, Rest, EndIndex) :-
    NextIndex is Index + 1,
    findNeg(Xs, NextIndex, XIndex, XValue, Rest, EndIndex).
findNeg([X | Xs], Index, Index, X, Xs, NextIndex) :-
    NextIndex is Index + 1,
    X < 0.

% Najde zaporne cislo, vrati jeho index, hodnotu, zbytek pole
findSome([_ | Xs], Index, XIndex, XValue, Rest, EndIndex) :-
    NextIndex is Index + 1,
    findSome(Xs, NextIndex, XIndex, XValue, Rest, EndIndex).
findSome([X | Xs], Index, Index, X, Xs, NextIndex) :-
    NextIndex is Index + 1.

% Najde kladne cislo, zaporne cislo a libovolne cislo v tomto poradi
findTriple(Xs, Ai, Bi, Ci, A, B, C) :-
    findPos(Xs, 0, Ai, A, Rest1, Ind1),
    findNeg(Rest1, Ind1, Bi, B, Rest2, Ind2),
    findSome(Rest2, Ind2, Ci, C, _, _).

% Vezme prostredni (zaporne) cislo a navazi AG tak, aby se vynulovalo
constructAG(Ai, Bi, Ci, _, B, _, AGA, B, AGC) :-
    AGA is -(Ci-Bi)/(Ci-Ai)*B,
    AGC is -(Bi-Ai)/(Ci-Ai)*B.

% Pricte dane cislo na danou pozici
addToPos(_, _, _, [], []).
addToPos(Ai, A, Ai, [X | Xs], [Y | Ys]) :-
    Y is X + A,
    NextIndex is Ai+1,
    addToPos(Ai, A, NextIndex, Xs, Ys).
addToPos(Ai, A, Index, [X | Xs], [X | Ys]) :-
    Ai =\= Index,
    NextIndex is Index+1,
    addToPos(Ai, A, NextIndex, Xs, Ys).

% Odecte vytvorene AG od pole koeficientu
substractAG(Xs, Ai, Bi, Ci, A, B, C, Substracted) :-
    addToPos(Ai, -A, 0, Xs, Ys),
    addToPos(Bi, -B, 0, Ys, Zs),
    addToPos(Ci, -C, 0, Zs, Substracted).


% ------------------- Vypisovani ------------------


% Udela string tvaru C^I
expToString(_, 0, Str) :-
    format(atom(Str), '', []).
expToString(C, 1, Str) :-
    format(atom(Str), '~s', [C]).
expToString(C, D, Str) :-
    format(atom(Str), '~s^~d', [C, D]).

% Prida znamenko + pokud to neni prvni clen
maybeAddSign(Str, false, Str).
maybeAddSign(In, true, Str) :-
    format(atom(Str), ' \t+ \t~s', [In]).

% Udela string tvaru Ka^Ib^J
termToString(term(K, I, J), Str) :- 
    expToString('a', I, StrA),
    expToString('b', J, StrB),
    format(atom(Str), '~2f~s~s', [K, StrA, StrB]).

repeatedTerm(Term, 1, Plus, Str) :-
    termToString(Term, Str1),
    maybeAddSign(Str1, Plus, Str), !.
repeatedTerm(Term, Times, Plus, Str) :-
    termToString(Term, Str1),
    maybeAddSign(Str1, Plus, Str2),
    Times2 is Times-1,
    repeatedTerm(Term, Times2, true, Str3),
    format(atom(Str), '~s~s', [Str2, Str3]).

% Prevede AG na string
aGToString(Ai, Bi, Ci, A, B, C, Degree, Str) :-
    AiD is Degree-Ai,
    BiD is Degree-Bi,
    CiD is Degree-Ci,
    ATimes is Ci-Bi,
    A2 is A/ATimes,
    CTimes is Bi-Ai,
    C2 is C/CTimes,
    repeatedTerm(term(A2, AiD, Ai), ATimes, false, StrA),
    termToString(term(-B, BiD, Bi), StrB),
    repeatedTerm(term(C2, CiD, Ci), CTimes, false, StrC),
    format(atom(Str), '~s \t+ \t~s \t>= \t~s\n', [StrA, StrC, StrB]).

% Prevede posloupnost nezapornych koeficientu na string
% Pokud jsou to same nuly, bude to prazdny string
trivialToString(Xs, _, "") :-
    sum(Xs, Sum),
    Sum < 0.0001.
trivialToString(Xs, Degree, Str) :-
    once(trivialToString(Xs, 0, Degree, false, Str)).


% Prevede posloupnost kladnych koeficientu na nerovnost
trivialToString([], _, _, _, " \t>= \t0\n").
trivialToString([X | Xs], Index, Degree, Sign,  Str) :-
    X < 0.0001,
    NextIndex is Index+1,
    once(trivialToString(Xs, NextIndex, Degree, Sign, Str)).
trivialToString([X | Xs], Index, Degree, Sign, Str) :-
    X > 0.0001,
    NextIndex is Index + 1,
    once(trivialToString(Xs, NextIndex, Degree, true, Str2)),
    D is Degree - Index,
    termToString(term(X, D, Index), Str1),
    maybeAddSign(Str1, Sign, Str3),
    format(atom(Str), '~s~s', [Str3, Str2]).


% ---------------------- RESENI -------------------------


% Zkontroluje, ze pole nezacina ani nekonci zapornym cislem, pak by nerovnost zrejme neplatila
% Jsou tam nejake epsilony, protoze jinak by floaty mohly byt zle
checkEnds([], true, true, false).
checkEnds([], false, false, true).
checkEnds([X | Xs], _, _, _) :-
    X > -0.0001,
    checkEnds(Xs, true, true, false).
checkEnds([X | Xs], true, _, _) :-
    X < -0.0001,
    checkEnds(Xs, true, false, false).
checkEnds([0 | Xs], FirstPos, LastPos, AllZero) :-
    checkEnds(Xs, FirstPos, LastPos, AllZero).

checkEnds(Xs) :- 
    checkEnds(Xs, false, false, true).

% Zkontroluje, jestli jsou vsechny koeficienty kladne a nerovnost je trivialni
trivial([]).
trivial([X | Xs]) :- 
    X >= -0.0001,
    trivial(Xs).


% Udela jeden dokazovaci krok - najde a odecte AG, vrati string, ktery ho popisuje
step(Xs, Degree, Substracted, Mess) :-
    findTriple(Xs, Ai, Bi, Ci, A, B, C),
    constructAG(Ai, Bi, Ci, A, B, C, AGA, AGB, AGC),
    substractAG(Xs, Ai, Bi, Ci, AGA, AGB, AGC, Substracted),
    once(aGToString(Ai, Bi, Ci, AGA, AGB, AGC, Degree, Mess)).


% Vyresi trivialni nerovnost
solve(Xs, Degree, Str) :-
    trivial(Xs),
    once(trivialToString(Xs, Degree, Str)).

% Vyresi netrivialni nerovnost
solve(Xs, Degree, Mess) :-
    checkEnds(Xs),
    step(Xs, Degree, Next, Mess1),
    solve(Next, Degree, Mess2),
    format(atom(Mess), '~s~s', [Mess1, Mess2]).

% Vytvori pole nul dane velikosti
getZeros(0, []).
getZeros(N, [0 | Zeros]) :-
    N > 0,
    N2 is N-1,
    getZeros(N2, Zeros).

% Pricte seznam clenu k danemu poli
addTerms([], Xs, Xs).
addTerms([term(K, _, J) | Terms], Xs, Rs) :-
    addTerms(Terms, Xs, Zs),
    addToPos(J, K, 0, Zs, Rs).

% Otestuje, jestli je posloupnost clenu homogenni
testHomogeneous([term(_, I, J)], Degree) :-
    Degree is I + J.
testHomogeneous([term(_, I, J) | Terms], Degree) :-
    Degree is I + J,
    testHomogeneous(Terms, Degree).

% Secte pole
sum([], 0).
sum([X | Xs], Sum) :-
    sum(Xs, S),
    Sum is X + S.

% Zkusi dokazat nerovnost z posloupnosti koeficientu
proveCoefs(Xs, _, "There exists a counterexample.") :-
    \+ checkEnds(Xs).
proveCoefs(Xs, _, "There exists a counterexample.") :-
    sum(Xs, Sum),
    Sum < -0.0001.
proveCoefs(Xs, Degree, Mess) :-
    solve(Xs, Degree, Mess1),
    format(atom(Mess), '~s~s', ["This can be proven as a sum of the following inequalities:\n", Mess1]).
proveCoefs(_, _, "This is a tough one...").

% Zkusi dokazat nerovnost ze seznamu clenu
proveTerms(Terms, "The expression is not homogeneous, I can't prove that :-(") :-
    \+ testHomogeneous(Terms, _).
proveTerms(Terms, Mess) :-
    testHomogeneous(Terms, Degree),
    Degree1 is Degree+1,
    getZeros(Degree1, Zeros),
    addTerms(Terms, Zeros, Xs),
    once(proveCoefs(Xs, Degree, Mess)).

% Zkusi naparsovat string a dokazat nerovnost
prove(String) :-
    parseTerms(String, Terms),
    once(proveTerms(Terms, Message)),
    write(Message), !.
prove(String) :-
    \+ parseTerms(String, _),
    write("Could not parse the expression.").
