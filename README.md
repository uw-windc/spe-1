# spe-1

This is a simple partial equilibrium (spatial) model with differentiated goods.  The model is solved as a system of nonlinear equations.  The GAMS model file can be solved with the a "solve _modelname_ using cns" command or, as is shown here, the model specifies a zero objective function and then uses a "solve _modelname_ using nlp maximizing _objective_" command.  To solve a nonlinear system of equations in Julia/JuMP you do not need to specific the objective function. This model also writes out a _report_ variable to a CSV file.

The .gms file is provided for GAMS users and a translated version of the .gms file is provided in Julia/JuMP format (.jl).  Data from the .gms file is output to a GDX container and then converted into a JSON file with gdx2json.py.  The Julia/JuMP model then reads the data directly in from the JSON file.

In order to run the gdx2json.py script the user will need to install the GAMS Python API (https://www.gams.com/latest/docs/API_PY_OVERVIEW.html)... and may need to create a Python 3 environment with the following .yml file.  Conda was used as the Python package manager and is recommended to create this environment.  Information on how to import this environment is available here: https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html#sharing-an-environment

The solution between the GAMS model and the Julia/JuMP model has been verified to be the same.


# Requirements
Python 3 (see .yml for exact environment), GAMS Python API, Julia 1.1.0 (JuMP, JSON, Ipopt, DataFrames, and CSV packages)


# Use
To recreate the original data GDX container and the JSON file that is used to populate the .jl file simply run
```
gams spe.gms
```

To execute the Julia/JuMP model with the existing JSON file simply run
```
julia spe.jl
```
