# Simple inequality prover in prolog

Tries to prove homogenous inequality in variables `a` and `b` as sum of AG - inequalities.

## Usage

Only important predicate is `prove`, gets expression in `a` and `b` as input and tries to prove that it is non-negative.

## Examples

Prover can prove for example following inequalities:

`prove("1 - 2 + 3").`\
`prove("a^2 - 2ab + b^2").`\
`prove("3a^3 - 5a^2b + ab^2 + b^3").`\
`prove("2a^4 - 3a^3b - 3ab^3 + 4b^4 + a^4").`\
`prove("a^5 - 2a^4b + 2a^3b^2 - a^2b^3 - ab^4 + b^5").`\
`prove("a^10 - a^9b - ab^9 + b^10").`

Recognizes if the inequality is obviously not true:

`prove("3 - 5 + 1").`\
`prove("10a^3 + 7ab^2 - b^3").`\
`prove("a^4 - 3a^2b^2 + b^4").`

However, It can't correctly solve for example following cases:

`prove("a^2b^2 + 1 - 2ab").`\
`prove("a^2 + 4b^2 - 4ab").`\
`prove("a^10 - 2ab^9 + b^10").`\
`prove("a^10 - a^5b^5 - ab^9 + b^10").`