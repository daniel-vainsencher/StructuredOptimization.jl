function mergeProx(x_sorted::Vector{Variable}, cf::CostFunction)
	if length(x_sorted) == 1 #no block variables
		return mergeProx(terms(cf), affine(cf))
	else
		p = Vector{ProximableFunction}(length(x_sorted))
		fi   = Vector{ExtendedRealValuedFunction}()
		Ai   = Vector{AffineOperator}()
		for i in eachindex(x_sorted)
			for ii in eachindex(affine(cf))
				if variable(affine(cf)[ii])[1] == x_sorted[i]
					push!(fi,  terms(cf)[ii]) 
					push!(Ai, affine(cf)[ii]) 
				end
			end
			p[i] = mergeProx(fi,Ai)
		
			fi   = Vector{ExtendedRealValuedFunction}() #reinitialize the arrays
			Ai   = Vector{AffineOperator}()
		end
		return SeparableSum(p)
	end
end

function mergeProx(f::Vector{ExtendedRealValuedFunction}, affOps::Vector{AffineOperator})
	if length(f) <= 1 
		if isempty(f)
			p = IndFree()
		else
			p = absorbOp(affOps[1], get_prox(f[1]) )
		end
	else
		if all([typeof(A) <: GetIndex for A in  operator.(affOps)])
			idxs = get_idx.(operator.(affOps))
			ps = absorbOp.(affOps, get_prox.(f) )
			p = SlicedSeparableSum(ps,idxs)
		else
			error("too many terms with the same variables!")
		end
	end
end

isempty(p::ProximableFunction) = typeof(p) <: IndFree
isempty(p::SeparableSum) = all([typeof(f)  <: IndFree for f in p.fs ])

# absorb linear operator into proximable operator
absorbOp(A::AffineOperator, p::ProximableFunction) = absorbOp(operator(A), p, tilt(A))
absorbOp(A::Vector{AffineOperator}, p::Vector{ProximableFunction}) = 
absorbOp.(operator(A), p, tilt.(A))

absorbOp{L <:Union{IdentityOperator,GetIndex}}(A::L, p::ProximableFunction, b) = 
b == 0. ? p : PrecomposeDiagonal(p, 1., b)
absorbOp{L <: Scale}(A::L, p::ProximableFunction, b) = 
b == 0. ? p : PrecomposeDiagonal(p, A.coeff, b)
absorbOp{L <:DiagonalOperator}(A::L, p::ProximableFunction, b) = PrecomposeDiagonal(p, A.d, b)

# merge Proximal operators 
mergeProx{T<:AffineOperator}(p::ProximableFunction, lambda, A::T) =  Regularize(p, lambda, -tilt(A.b))
mergeProx{T<:LinearOperator}(p::ProximableFunction, lambda, A::T) =  Regularize(p, lambda,     0.    )




