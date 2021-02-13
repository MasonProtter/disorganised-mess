module MoreAnalysis

export bound_variable_connections_graph

import Pluto
import Pluto: Cell, Notebook, NotebookTopology



"Find all subexpressions of the form `@bind symbol something`, and extract the `symbol`s."
function find_bound_variables(expr)
	found = Set{Symbol}()
	find_bound_variables!(found, expr)
	found
end

function find_bound_variables!(found::Set{Symbol}, expr::Expr)
	if expr.head === :macrocall && expr.args[1] === Symbol("@bind") && length(expr.args) == 4
		push!(found, expr.args[3])
		find_bound_variables!(found, expr.args[4])
	else
		for a in expr.args
			find_bound_variables!(found, a)
		end
	end
end

function find_bound_variables!(found::Set{Symbol}, expr::Any) end




"Return the given cells, and all cells that depend on them (recursively)."
function downstream_recursive(notebook::Notebook, topology::NotebookTopology, from::Union{Vector{Cell},Set{Cell}})
    found = Set{Cell}(copy(from))
    downstream_recursive!(found, notebook, topology, from)
    found
end

function downstream_recursive!(found::Set{Cell}, notebook::Notebook, topology::NotebookTopology, from::Vector{Cell})
    for cell in from
        one_down = Pluto.where_referenced(notebook, topology, cell)
        for next in one_down
            if next ∉ found
                push!(found, next)
                downstream_recursive!(found, notebook, topology, Cell[next])
            end
        end
    end
end




"Return all cells that are depended upon by any of the given cells."
function upstream_recursive(notebook::Notebook, topology::NotebookTopology, from::Union{Vector{Cell},Set{Cell}})
    found = Set{Cell}(copy(from))
    upstream_recursive!(found, notebook, topology, from)
    found
end

function upstream_recursive!(found::Set{Cell}, notebook::Notebook, topology::NotebookTopology, from::Vector{Cell})
    for cell in from
        references = topology[cell].references
        for upstream in Pluto.where_assigned(notebook, topology, references)
            if upstream ∉ found
                push!(found, upstream)
                upstream_recursive!(found, notebook, topology, Cell[upstream])
            end
        end
    end
end

"All cells that can affect the outcome of changing the given variable."
function codependents(notebook::Notebook, topology::NotebookTopology, var::Symbol)
    assigned_in = filter(notebook.cells) do cell
        var ∈ topology[cell].definitions
    end
    
    downstream = collect(downstream_recursive(notebook, topology, assigned_in))

    downupstream = upstream_recursive(notebook, topology, downstream)
end

"Return a `Dict{Symbol,Vector{Symbol}}` where the _keys_ are the bound variables of the notebook.

For each key (a bound symbol), the value is the list of (other) bound variables whose values need to be known to compute the result of setting the bond."
function bound_variable_connections_graph(notebook::Notebook)
    topology = notebook.topology
    bound_variables = union(map(notebook.cells) do cell
        find_bound_variables(cell.parsedcode)
    end...)
    Dict{Symbol,Vector{Symbol}}(
        var => let
            cells = codependents(notebook, topology, var)
            defined_there = union!(Set{Symbol}(), (topology[c].definitions for c in cells)...)
            collect(defined_there ∩ bound_variables)
        end
        for var in bound_variables
    )
end
end


# s = Pluto.ServerSession(options=Pluto.Configuration.from_flat_kwargs(workspace_use_distributed=true))
# nb = let
#     path = "/Users/fons/Documents/PlutoBindServer.jl/test/parallelpaths.jl"

#     begin
#         newpath = tempname()
#         write(newpath, read(path))
#         newpath
#     end
    
#     Pluto.SessionActions.open(s, newpath; run_async=false)
# end


# bound_variable_connections_graph(nb)
