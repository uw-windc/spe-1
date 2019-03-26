$title	Simple Partial Equilibrium Trade Model

set		r	Regions /r1*r10/;

alias (r,rr);

parameter	x0(r,rr)	Benchmark supply
		eta(r)		Elasticity of supply
		esub(r)		Elasticity of substitution
		sigma(r)	Elasticity of demand
		y0(r)		Benchmark output
		theta(r,rr)	Value share;


$GDXIN spe_data
$LOADDC x0
$LOADDC y0
$LOADDC eta
$LOADDC esub
$LOADDC sigma
$GDXIN

* x0(r,rr) = uniform(0,1);
* y0(r) = sum(rr, x0(r,rr));
* eta(r) = uniform(0,1);
* esub(r) = uniform(2,8);
* sigma(r) = uniform(1,3);

* unload data to use in the Julia/JuMP version
* EXECUTE_UNLOAD 'spe_data.gdx',r,x0,y0,eta,esub,sigma;
EXECUTE 'python3 ./gdx2json.py --in=spe_data.gdx';



theta(r,rr) = x0(r,rr) / sum(r.local, x0(r,rr));
display theta;

variables	P(r)		Equilibrium price,
		Y(r)		Equilibrium supply,
		C(r)		Unit cost,
		X(r,rr)		Demand
		OBJ		Vacuous objective;

equations objdef, output, supply, demand, cost;

objdef..	OBJ =e= 0;

output(r)..	Y(r) =e= sum(rr, X(r,rr));

supply(r)..	Y(r) =e= y0(r) * P(r)**eta(r);

demand(r,rr)..	X(r,rr) =e= x0(r,rr) * (C(rr)/P(r))**esub(rr) * C(rr)**(-sigma(rr));

cost(r)..	C(r) =e= sum(rr, theta(rr,r) * P(r)**(1-esub(r)))**(1/(1-esub(r)));

model armington /objdef, output, supply, demand, cost/;

P.L(r) = 1;
Y.L(r) = y0(r);
C.L(r) = 1;
X.L(r,rr) = x0(r,rr);
OBJ.L = 0;

parameter	report		Summary report;
report(r,"P","bmk") = P.L(r);
report(r,"Y","bmk") = Y.L(r);
report(r,"C","bmk") = C.L(r);

option nlp=ipopt;
solve armington using nlp maximizing obj;

report(r,"P","solve_1") = P.L(r);
report(r,"Y","solve_1") = Y.L(r);
report(r,"C","solve_1") = C.L(r);


P.L(r) = uniform(0,2);
Y.L(r) = uniform(0,2*y0(r));
C.L(r) = uniform(0,2);
solve armington using nlp maximizing obj;


report(r,"P","solve_2") = P.L(r);
report(r,"Y","solve_2") = Y.L(r);
report(r,"C","solve_2") = C.L(r);


EXECUTE_UNLOAD 'spe_soln.gdx' report;
