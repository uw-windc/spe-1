using JuMP, JSON, Ipopt, DataFrames, CSV


d = JSON.Parser.parsefile("spe_data.json")


function parse_data(key)
    x = Dict()

    if d[key]["type"] == "GamsSet"
        if d[key]["dimension"] == 1
            x = d[key]["elements"]
            return x
        end
    end

    # need to work on import multidimentional sets (i.e., mappings)

    if d[key]["type"] == "GamsParameter"
        if d[key]["dimension"] == 0
            x = d[key]["values"]
            return x
        end

        if d[key]["dimension"] == 1
            for i in 1:length(d[key]["values"]["domain"])
                a = d[key]["values"]["domain"][i]
                x[a] = d[key]["values"]["data"][i]
            end
            return x
        end

        if d[key]["dimension"] > 1
            for i in 1:length(d[key]["values"]["domain"])
                a = tuple(d[key]["values"]["domain"][i]...)
                x[a] = d[key]["values"]["data"][i]
            end
        return x
        end
    end
end


# data pull
r = parse_data("r")
esub = parse_data("esub")
sigma = parse_data("sigma")
x0 = parse_data("x0")
eta = parse_data("eta")
y0 = parse_data("y0")




# pre-processing calculations
theta = Dict()
for i in r
    for j in r
        theta[i,j] = x0[i,j] / sum(x0[i,j] for i in r)
    end
end



# model object
m = Model(with_optimizer(Ipopt.Optimizer, print_level = 0))

# add variables and initial point to model object
@variable(m, P[i in r], start=1)
@variable(m, Y[i in r], start=y0[i])
@variable(m, C[i in r], start=1)
@variable(m, X[i in r, j in r], start=x0[i,j])


# add constartins to model object
@constraint(m, output[i in r], sum(X[i,j] for j in r) == Y[i] )
@NLconstraint(m, supply[i in r], Y[i] == y0[i] * P[i]^eta[i] )
@NLconstraint(m, demand[i in r, j in r], X[i,j] == x0[i,j] * (C[j]/P[i])^esub[j] * C[j]^(-sigma[j]) )
@NLconstraint(m, cost[j in r], C[j] == sum(theta[i,j] * P[j]^(1-esub[j]) for i in r)^(1/(1-esub[j])) )


report = Dict()
for i in r report[i,"P","bmk"] = 1 end
for i in r report[i,"Y","bmk"] = y0[i] end
for i in r report[i,"C","bmk"] = 1 end


# solve #1
optimize!(m)

# post processing / output solution check
print(termination_status(m))
print(primal_status(m))
print(dual_status(m))

for i in r report[i,"P","solve_1"] = value(P[i]) end
for i in r report[i,"Y","solve_1"] = value(Y[i]) end
for i in r report[i,"C","solve_1"] = value(C[i]) end


# solve #2
for i in r fix(Y[i], 2*y0[i]) end
optimize!(m)

for i in r report[i,"P","solve_2"] = value(P[i]) end
for i in r report[i,"Y","solve_2"] = value(Y[i]) end
for i in r report[i,"C","solve_2"] = value(C[i]) end

# sort by keys
report = sort(report)



# # CSV write output
# df = DataFrame(Region=String[], Variable=String[], Solve=String[], Value=Float64[])
#
# for i in collect(keys(report))
#     region, variable, solve = i
#     value = report[i]
#     push!(df, [region,variable, solve, value])
# end
#
# CSV.write("julia_solve.csv", df)
