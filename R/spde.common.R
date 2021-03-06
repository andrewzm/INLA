## Export: inla.dBind inla.extract.el inla.extract.el!data.frame
## Export: inla.extract.el!list inla.extract.el!matrix inla.matern.cov
## Export: inla.matern.cov.s2 inla.row.kron
## Export: inla.spde.make.A inla.spde.make.block.A inla.spde.make.index
## Export: inla.spde.models inla.spde.precision inla.spde.result
## Export: inla.spde.sample inla.spde.sample!default
## Export: inla.spde.sample!inla.spde inla.stack inla.stack.A
## Export: inla.stack.LHS inla.stack.RHS inla.stack.compress
## Export: inla.stack.data inla.stack.sum
## Export: inla.stack.index inla.stack.join
## Export: inla.stack.remove.unused rbind!inla.data.stack.info
## Internal: inla.spde.homogenise_B_matrix inla.regex.match

inla.dBind <- function(...)
{
    return(.bdiag(list(...)))
}

inla.extract.el <- function(M, ...)
{
    if (is.null(M))
        return(NULL)
    UseMethod("inla.extract.el", M)
}

inla.regex.match =  function(x, match) {
    return(strsplit(x, match)[[1]][1]=="")
}

inla.extract.el.matrix <- function(M, match, by.row=TRUE, ...)
{
    if (by.row) {
        return(M[sapply(rownames(M), inla.regex.match, match=match),,drop=FALSE])
    } else {
        return(M[,sapply(colnames(M), inla.regex.match, match=match),drop=FALSE])
    }
}

inla.extract.el.data.frame <- function(M, match, by.row=TRUE, ...)
{
    if (by.row) {
        return(M[sapply(rownames(M), inla.regex.match, match=match),,drop=FALSE])
    } else {
        return(M[,sapply(colnames(M), inla.regex.match, match=match),drop=FALSE])
    }
}

inla.extract.el.list <- function(M, match, ...)
{
    return(M[sapply(names(M), inla.regex.match, match=match)])
}



inla.spde.homogenise_B_matrix <- function(B, n.spde, n.theta)
{
    if (!is.numeric(B))
        stop("B matrix must be numeric.")
    if (is.matrix(B)) {
        if ((nrow(B) != 1) && (nrow(B) != n.spde)) {
            stop(inla.paste(list("B matrix has",
                                 as.character(nrow(B)),
                                 "rows but should have 1 or",
                                 as.character(n.spde),
                                 sep=" ")))
        }
        if ((ncol(B) != 1) && (ncol(B) != 1+n.theta)) {
            stop(inla.paste(list("B matrix has",
                                 as.character(ncol(B)),
                                 "columns but should have 1 or",
                                 as.character(1+n.theta),
                                 sep=" ")))
        }
        if (ncol(B) == 1) {
            return(cbind(as.vector(B), matrix(0.0, n.spde, n.theta)))
        } else if (ncol(B) == 1+n.theta) {
            if (nrow(B) == 1) {
                return(matrix(as.vector(B), n.spde, 1+n.theta, byrow=TRUE))
            } else if (nrow(B) == n.spde) {
                return(B)
            }
        }
    } else { ## !is.matrix(B)
        if ((length(B) == 1) || (length(B) == n.spde)) {
            return(cbind(B, matrix(0.0, n.spde, n.theta)))
        } else if (length(B) == 1+n.theta) {
            return(matrix(B, n.spde, 1+n.theta, byrow=TRUE))
        } else {
            stop(inla.paste(list("Length of B vector is",
                                 as.character(length(B)),
                                 "but should be 1,",
                                 as.character(1+n.theta), "or",
                                 as.character(n.spde)),
                            sep=" "))
        }
    }
    stop(inla.paste(list("Unrecognised structure for B matrix"),
                    sep=" "))
}



inla.matern.cov <- function(nu,kappa,x,d=1,corr=FALSE, norm.corr=FALSE, theta, epsilon=1e-8)
{
    if (missing(theta)) { ## Ordinary Matern
        y = kappa*abs(x)
        if (corr) {
            ok = (y>=epsilon)
            if (nu<=0) {
                covariance = y*0
                covariance[!ok] = 1-y/epsilon
            } else {
                covariance = y*0
                covariance[ok] =
                    2^(1-nu)/gamma(nu) * (y[ok])^nu*besselK(y[ok], nu)
                if (any(!ok)) {
                    scale = 2^(1-nu)/gamma(nu)
                    ## corr = scale y^nu K_nu(y)
                    ##      = 1 - b y^(2 nu) + o(y^(2 nu), 0 < \nu < 1
                    ##      = 1 - b y^2 + o(y^2), 1 <= \nu
                    ## (1-corr(eps)/vari)/eps^(2nu) = b
                    if (nu < 1) {
                        exponent = 2*nu
                    } else {
                        exponent = 2
                    }
                    corr.eps <-
                        scale * epsilon^nu * besselK(epsilon, nu)
                    b = (1-corr.eps)/epsilon^exponent
                    covariance[!ok] = (1-b*y[!ok]^exponent)
                }
            }
            return(covariance)
        } else {
            ok = (y>=epsilon)
            covariance = y*0
            covariance[ok] =
                2^(1-nu)/gamma(nu+d/2)/(4*pi)^(d/2)/kappa^(2*nu)*
                    (y[ok])^nu*besselK(y[ok], nu)
            if (any(!ok)) {
                if (nu>0) { ## Regular Matern case
                    vari = gamma(nu)/gamma(nu+d/2)/(4*pi)^(d/2)/kappa^(2*nu)
                    scale = 2^(1-nu)/gamma(nu)
                    ## corr = scale y^nu K_nu(y)
                    ##      = 1 - b y^(2 nu) + o(y^(2 nu), 0 < \nu < 1
                    ##      = 1 - b y^2 + o(y^2), 1 <= \nu
                    ## (1-corr(eps)/vari)/eps^(2nu) = b
                    if (nu < 1) {
                        exponent = 2*nu
                    } else {
                        exponent = 2
                    }
                    corr.eps <-
                        scale * epsilon^nu * besselK(epsilon, nu)
                    b = (1-corr.eps)/epsilon^exponent
                    covariance[!ok] = vari*(1-b*y[!ok]^exponent)
                } else if (nu==0) { ## Limiting Matern case
                    g = 0.577215664901484 ## Euler's constant
                    covariance[!ok] =
                        2/gamma(d/2)/(4*pi)^(d/2)*
                            (-log(y[!ok]/2)-g)
                } else { ## (nu<0)
                    ## TODO: check this...
                    covariance[!ok] =
                        ((2^(1-nu)/gamma(nu+d/2)/(4*pi)^(d/2)/kappa^(2*nu)*
                          gamma(nu)*2^(nu-1))*(1-(y[!ok]/epsilon)) +
                         (2^(1-nu)/gamma(nu+d/2)/(4*pi)^(d/2)/kappa^(2*nu)*
                          epsilon^nu*besselK(epsilon, nu))*(y[!ok]/epsilon))
                }
            }
            return(covariance)
        }
    } else { ## Oscillating covariances
        y = abs(x)
        if (d>2L) {
            warning('Dimension > 2 not implemented for oscillating models.')
        }
        freq.max = 1000/max(y)
        freq.n = 10000
        w = seq(0,freq.max,length.out=freq.n)
        dw = w[2]-w[1]
        spec = 1/(2*pi)^d/(kappa^4+2*kappa^2*cos(pi*theta)*w^2+w^4)^((nu+d/2)/2)
       if (d==1L) {
            covariance = y*0+spec[1]*dw
        } else {
            covariance = y*0
        }
        for (k in 2:freq.n) {
            if (d==1L) {
                covariance = covariance+2*cos(y*w[k])*spec[k]*dw
            } else {
                covariance = covariance + w[k]*besselJ(y*w[k],0)*spec[k]*dw
            }
        }

        if (norm.corr) {
            noise.variance = 1/covariance[1]
        } else {
            noise.variance = 1
        }

        return(covariance*noise.variance)
    }
}


inla.matern.cov.s2 <- function(nu,kappa,x,norm.corr=FALSE,theta=0)
{
    inla.require("orthopolynom")
    y = cos(abs(x))

    freq.max = 40L
    freq.n = freq.max+1L
    w = 0L:freq.max
    spec = 1/(kappa^4+2*kappa^2*cos(pi*theta)*w*(w+1)+w^2*(w+1)^2)^((nu+1)/2)
    leg = legendre.polynomials(freq.max)
    covariance = y*0
    for (k in 1:freq.n) {
        covariance = (covariance + (2*w[k]+1)/(4*pi)*spec[k]*
                      polynomial.values(leg[k],y)[[1]])
    }

    if (norm.corr) {
        noise.variance = 1/covariance[1]
    } else {
        noise.variance = 1
    }

    return(covariance*noise.variance)
}



inla.spde.models <- function(function.names=FALSE)
{
    types = c("spde1", "spde2")
    models = list()
    for (t in types) {
        models[[t]] =
            do.call(what=paste("inla.", t, ".models", sep=""),
                    args=list())
        if (function.names) {
            models[[t]] = paste("inla.", t, ".", models[[t]], sep="")
        }
    }

    if (function.names) {
        models = as.vector(do.call(c, models))
    }

    return(models)
}


inla.spde.sample <- function(...)
{
    warning("inla.spde.sample is deprecated.  Please use inla.qsample() in combination with inla.spde.precision() instead.")
    UseMethod("inla.spde.sample")
}

inla.spde.sample.default =
    function(precision, seed=NULL, ...)
{
    return(inla.finn(precision,
                     seed=(inla.ifelse(is.null(seed),
                                       0L,
                                       seed)))$sample)
}

inla.spde.sample.inla.spde =
    function(spde, seed=NULL, ...)
{
    precision = inla.spde.precision(spde, ...)
    return(inla.spde.sample(precision, seed=seed))
}



inla.spde.precision <- function(...)
{
    UseMethod("inla.spde.precision")
}

inla.spde.result <- function(...)
{
    inla.require.inherits(list(...)[[1]], "inla", "First parameter")
    inla.require.inherits(list(...)[[2]], "character", "Second parameter")
    UseMethod("inla.spde.result", list(...)[[3]])
}







inla.spde.make.index <- function(name, n.spde, n.group=1, n.repl=1, ...)
{
    if ("n.mesh" %in% names(list(...))) {
        warning("'n.mesh' is deprecated, please use 'n.spde' instead.")
        if (missing(n.spde) || is.null(n.spde))
            n.spde = list(...)$n.mesh
    }

    name.group = paste(name, ".group", sep="")
    name.repl = paste(name, ".repl", sep="")
    out = list()
    out[[name]]       = rep(rep(1:n.spde, times=n.group), times=n.repl)
    out[[name.group]] = rep(rep(1:n.group, each=n.spde), times=n.repl)
    out[[name.repl]]  = rep(1:n.repl, each=n.spde*n.group)
    return(out)
}





inla.row.kron <- function(M1, M2, repl=NULL, n.repl=NULL, weights=NULL) {
    M1 = inla.as.dgTMatrix(M1)
    M2 = inla.as.dgTMatrix(M2)
    n = nrow(M1)
    if (is.null(repl)) {
        repl = rep(1L, n)
    }
    if (is.null(n.repl)) {
        n.repl = max(repl)
    }
    if (is.null(weights)) {
        weights = rep(1, n)
    } else if (length(weights)==1L) {
        weights = rep(weights[1], n)
    }

    if (FALSE) {
    ## Slow version:
        print(system.time({
            M = (sparseMatrix(i=numeric(0), j=numeric(0), x=integer(0),
                              dims=c(n, ncol(M1)*ncol(M2))))
            for (k in seq_len(n)) {
                M[k,] = kronecker(M1[k,,drop=FALSE], M2[k,,drop=FALSE])
            }
            M = inla.as.dgTMatrix(M)
            weights.ii = weights[1L + M@i]
            M = (sparseMatrix(i=(1L + M@i),
                              j=(1L + M@j + ncol(M)*(repl[M@i+1L]-1L)),
                      x=weights.ii*M@x,
                              dims=c(n, n.repl*ncol(M))))
        }))
        M.slow = M
    }

    ## Fast version:
    ## TODO: Check robustness for all-zero rows.
    ## TODO: Maybe move big sparseMatrix call outside the loop.
    ## TODO: Automatically choose M1 or M2 for looping.

##    print(system.time({
    n1 = (as.vector(sparseMatrix(i=1L+M1@i, j=rep(1L, length(M1@i)),
                                 x=1L, dims=c(n, 1))))
    n2 = (as.vector(sparseMatrix(i=1L+M2@i, j=rep(1L, length(M2@i)),
                                 x=1L, dims=c(n, 1))))

    M = (sparseMatrix(i=integer(0), j=integer(0), x=numeric(0),
                      dims=c(n, ncol(M2)*ncol(M1)*n.repl)))
    n1 = n1[1L+M1@i]
    for (k in unique(n1)) {
        sub = which(n1==k)
        n.sub = length(sub)

        i.sub = 1L+M1@i[sub]
        j.sub = 1L+M1@j[sub]
        o1 = order(i.sub, j.sub)
        jj = rep(seq_len(k), times=n.sub/k)

        i.sub = i.sub[o1]
        j.sub = (sparseMatrix(i=i.sub,
                              j=jj,
                              x=j.sub[o1],
                              dims=c(n, k)))
        x.sub = (sparseMatrix(i=i.sub,
                              j=jj,
                              x=weights[i.sub]*M1@x[sub][o1],
                              dims=c(n, k)))
        sub2 = which(is.element(1L+M2@i, i.sub))

        if (length(sub2) > 0) {
            i = 1L+M2@i[sub2]
            ii = rep(i, times=k)
            repl.i = repl[ii]

            M = (M +
                 sparseMatrix(i=ii,
                              j=(1L+rep(M2@j[sub2], times=k)+
                                 ncol(M2)*(as.vector(j.sub[i,])-1L)+
                                 ncol(M2)*ncol(M1)*(repl.i-1L)),
                              x=(rep(M2@x[sub2], times=k)*
                                 as.vector(x.sub[i,])),
                              dims=c(n, ncol(M2)*ncol(M1)*n.repl)))
        }
    }
##}))

    ## For debugging:
    ##    print(max(abs(M-M.slow)))

    ##    o2 = order(n2[1L+M2@i], M2@i, M2@j)

    return(M)
}




## Add A-matrix rows belonging to the same "block" with optional
## weights and optional rescaling, by dividing row i by a_i, for |a_i|>0:
## B(i) = {j; block(i)==block(j) and sum_k |A_jk| > 0 }
## "count":   a_i = #{j in B(i)} }
## "weights": a_i = \sum_{j in B(i)} weights_j
## "sum":     a_i = \sum_{j in B(i)} \sum_k A_jk weights_j
##
## This function makes use of the feature of sparseMatrix to sum all
## values for multiple instances of the same (i,j) pair.
inla.spde.make.block.A =
    function(A,
             block,
             n.block = max(block),
             weights = NULL,
             rescale = c("none", "count", "weights", "sum"))
{
    A = inla.as.dgTMatrix(A)
    N = nrow(A)
    ## length(block) should be == N or 1
    if (length(block) == 1L) {
        block = rep(block, N)
    }
    if (is.null(weights)) {
        weights = rep(1, N)
    }

    rescale = match.arg(rescale)

    if (!(rescale == "none")) {
        if (rescale == "count") {
            ## Count the non-zero rows within each block
            sums = (sparseMatrix(i = block,
                                 j = rep(1L, N),
                                 x = (rowSums(abs(A)) > 0) * 1.0,
                                 dims = c(n.block, 1L)
                                 ))[block]
        } else if (rescale == "weights") {
            ## Sum the weights within each block
            sums = (sparseMatrix(i = block,
                                 j = rep(1L, N),
                                 x = (rowSums(abs(A)) > 0) * weights,
                                 dims = c(n.block, 1L)
                                 ))[block]
        } else { ## (rescale == "sum"){
            ## Sum the weighted values within each block
            sums = (sparseMatrix(i = block,
                                 j = rep(1L, N),
                                 x = rowSums(A) * weights,
                                 dims = c(n.block, 1L)
                                 ))[block]
        }
        ## Normalise:
        ok = (abs(sums) > 0)
        weights[ok] = weights[ok]/sums[ok]
    }

    return(inla.as.dgTMatrix(sparseMatrix(i = block[1L+A@i],
                                          j = 1L+A@j,
                                          x = A@x * weights[1L+A@i],
                                          dims = c(n.block, ncol(A))
                                          )))
}



inla.spde.make.A =
    function(mesh = NULL,
             loc = NULL,
             index = NULL,
             group = NULL,
             repl = 1L,
             n.spde = NULL,
             n.group = NULL,
             n.repl = NULL,
             group.mesh = NULL,
             weights = NULL,
             A.loc = NULL,
             A.group = NULL,
             group.index = NULL,
             block = NULL,
             n.block = NULL,
             block.rescale = c("none", "count", "weights", "sum"),
             ...)
## Deprecated/obsolete parameters: n.mesh, group.method
{
    ## A.loc can be specified instead of mesh+loc, optionally with
    ## index supplied.
    ## A.group can be specified instead of group and/or group.mesh,
    ## optionally with group.index supplied.

    if ("n.mesh" %in% names(list(...))) {
        warning("'n.mesh' is deprecated, use 'n.spde' instead.")
        n.spde = list(...)$n.mesh
    }
    if ("group.method" %in% names(list(...))) {
        group.method =
            match.arg(list(...)$group.method, c("nearest", "S0", "S1"))
        warning(paste("'group.method=", group.method,
                      "' is deprecated.  Specify 'degree=",
                      switch(group.method, nearest="0", S0="0", S1="1"),
                      "' in inla.mesh.1d() instead.", sep=""))
    }

    if (is.null(mesh)) {
        if (is.null(A.loc) && is.null(n.spde))
            stop("At least one of 'mesh', 'n.spde', and 'A.loc' must be specified.")
        if (!is.null(A.loc)) {
            n.spde = ncol(A.loc)
        }
    } else {
        inla.require.inherits(mesh, c("inla.mesh", "inla.mesh.1d"), "'mesh'")
        if (inherits(mesh, "inla.mesh.1d")) {
            n.spde = mesh$m
        } else {
            n.spde = mesh$n
        }
    }
    if (!is.null(group.mesh)) {
        inla.require.inherits(group.mesh, "inla.mesh.1d", "'mesh'")
    }

    n.group =
        ifelse(!is.null(n.group),
               n.group,
               ifelse(!is.null(A.group),
                      nrow(A.group),
                      ifelse(!is.null(group.mesh),
                             group.mesh$m,
                             max(1,
                                 ifelse(is.null(group),
                                        1,
                                        ifelse(length(group)==0,
                                               1,
                                               max(group)))))))
    n.repl =
        ifelse(!is.null(n.repl),
               n.repl,
               max(1, ifelse(is.null(repl),
                             1,
                             ifelse(length(repl)==0,
                                    1,
                                    max(repl)))))

    ## Handle loc and index input semantics:
    if (is.null(loc)) {
        if (is.null(A.loc)) {
            A.loc = Diagonal(n.spde, 1)
        }
    } else {
        if (is.null(mesh))
            stop("'loc' specified but 'mesh' is NULL.")
        A.loc = inla.mesh.project(mesh, loc=loc)$A
    }
    if (is.null(index)) {
        index = seq_len(nrow(A.loc))
    }
    ## Now 'index' points into the rows of 'A.loc'

    if (is.null(n.block)) {
        n.block = ifelse(is.null(block), length(index), max(block))
    }
    block.rescale = match.arg(block.rescale)

    ## Handle group semantics:
    ## TODO: FIXME!!! group, group.index, group.mesh, A.group, etc
    if (!is.null(A.group)) {
        if (!is.null(group) || !is.null(group.mesh)) {
            warning("'A.group' has been specified; ignoring non-NULL 'group' or 'group.mesh'.")
        }
    } else if (!is.null(group.mesh)) {
        if (is.null(group)) {
            group = rep(group.mesh$mid[1], length(index))
        }
    } else if (is.null(group)) {
        group = rep(1L, length(index))
    } else if (length(group) == 1) {
        group = rep(group, length(index))
    }
    if (is.null(group.index)) {
        group.index = seq_len(length(group))
    }
    ## Now 'group.index' points into the rows of 'A.group' or 'group'
    if (length(group.index) != length(index)) {
        stop(paste("length(group.index) != length(index): ",
                   length(group.index), " != ", length(index),
                   sep=""))
    }

    if (!is.null(group.mesh) && is.null(A.group)) {
        A.group = inla.mesh.1d.A(group.mesh, loc=group)
    }
    ## Now 'group.index' points into the rows of 'A.group' or 'group'

    ## Handle repl semantics:
    if (is.null(repl)) {
        repl = rep(1, length(index))
    } else if (length(repl) == 1) {
        repl = rep(repl, length(index))
    } else if (length(repl) != length(index)) {
        stop(paste("length(repl) != length(index): ",
                   length(repl), " != ", length(index),
                   sep=""))
    }

    if (length(index) > 0L) {
        A.loc = inla.as.dgTMatrix(A.loc[index,,drop=FALSE])

        if (length(A.loc@i) > 0L) {
            if (is.null(weights)) {
                weights = rep(1, length(index))
            } else if (length(weights)==1L) {
                weights = rep(weights[1], length(index))
            }
            if (!is.null(block)) {
                ## Leave the rescaling until the block phase,
                ## so that the proper rescaling can be determined.
                block.weights = weights
                weights = rep(1, length(index))
            }

            if (!is.null(A.group)) {
                A.group = inla.as.dgTMatrix(A.group[group.index,,drop=FALSE])
                A = (inla.row.kron(A.group, A.loc,
                                   repl=repl, n.repl=n.repl,
                                   weights=weights))
                ## More general version:
                ## A = inla.row.kron(A.repl,
                ##                   inla.row.kron(A.group, A.loc),
                ##                   weights=weights))
            } else {
                i = 1L+A.loc@i
                group.i = group[group.index[i]]
                repl.i = repl[i]
                weights.i = weights[i]
                A = (sparseMatrix(i=i,
                                  j=(1L+A.loc@j+
                                     n.spde*(group.i-1L)+
                                     n.spde*n.group*(repl.i-1L)),
                                  x=weights.i*A.loc@x,
                                  dims=(c(length(index),
                                          n.spde*n.group*n.repl))))
            }
            if (!is.null(block)) {
                A = (inla.spde.make.block.A(A=A,
                                            block=block,
                                            n.block=n.block,
                                            weights=block.weights,
                                            rescale=block.rescale))
            }
        } else {
            A = (sparseMatrix(i=integer(0),
                              j=integer(0),
                              x=numeric(0),
                              dims=c(n.block, n.spde*n.group*n.repl)))
        }
    } else {
        A = (sparseMatrix(i=integer(0),
                          j=integer(0),
                          x=numeric(0),
                          dims=c(0L, n.spde*n.group*n.repl)))
    }
    return(A)
}




rbind.inla.data.stack.info <- function(...)
{
    l = list(...)
    names(l) = NULL
    names.tmp = do.call(c, lapply(l, function(x) x$names))
    ncol.tmp = do.call(c, lapply(l, function(x) x$ncol))

    ncol = c()
    names = list()
    for (k in 1:length(names.tmp)) {
        name = names(names.tmp)[k]
        if (!is.null(names[[name]])) {
            if (!identical(names[[name]],
                           names.tmp[[k]])) {
                stop("Name mismatch.")
            }
        }
        names[[name]] = names.tmp[[k]]

        if (!is.null(as.list(ncol)[[name]])) {
            if (ncol[name] != ncol.tmp[[k]]) {
                stop("ncol mismatch.")
            }
        }
        ncol[name] = ncol.tmp[[k]]
    }

    external.names = names(names)
    internal.names = do.call(c, names)

    factors = rep(FALSE, length(internal.names))
    names(factors) = internal.names
    factor.names <-
        lapply(l, function(x) do.call(c,
                                      x$names[do.call(c,
                                                      lapply(x$data,
                                                             is.factor))]))
    for (factor.loop in seq_along(l)) {
        factors[factor.names[[factor.loop]]] = TRUE
    }

    handle.missing.columns <- function(x) {
        missing.names =
            setdiff(internal.names,
                    do.call(c, x$names))
        if (length(missing.names)>0) {
            df <- c(rep(list(rep(NA, x$nrow)),
                        sum(!factors[missing.names])),
                    rep(list(rep(as.factor(NA), x$nrow)),
                        sum(factors[missing.names])))
            names(df) <- c(missing.names[!factors[missing.names]],
                           missing.names[factors[missing.names]])
            df = as.data.frame(df)
            return(cbind(x$data, df))
        } else {
            return(x$data)
        }
    }

    data = do.call(rbind, lapply(l, handle.missing.columns))

    offset = 0
    index = list()
    for (k in 1:length(l)) {
        for (j in 1:length(l[[k]]$index)) {
            if (is.null(index[[names(l[[k]]$index)[j]]])) {
                index[[names(l[[k]]$index)[j]]] = l[[k]]$index[[j]] + offset
            } else {
                index[[names(l[[k]]$index)[j]]] =
                    c(index[[names(l[[k]]$index)[j]]],
                      l[[k]]$index[[j]] + offset)
            }
        }
        offset = offset + l[[k]]$nrow
    }

    info =
        list(data=data,
             nrow=nrow(data),
             ncol=ncol,
             names=names,
             index=index)
    class(info) = "inla.data.stack.info"

    return(info)
}


inla.stack.remove.unused <- function(stack)
{
    inla.require.inherits(stack, "inla.data.stack", "'stack'")

    if (stack$effects$nrow<2) {
        return(stack)
    }

    ## Remove components with no effect:
    remove = rep(FALSE, stack$effects$nrow)
    remove.unused.indices =
        which(colSums(abs(stack$A[,,drop=FALSE]))==0)
    remove[remove.unused.indices] = TRUE

    index.new = rep(as.integer(NA), stack$effect$nrow)

    ncol.A = sum(!remove)
    if (ncol.A>0)
        index.new[!remove] = 1:ncol.A
    index.new[remove] = index.new[index.new[remove]]

    for (k in 1:length(stack$effects$index)) {
        stack$effects$index[[k]] = index.new[stack$effects$index[[k]]]
    }

    A = inla.as.dgTMatrix(stack$A)
    j.new = index.new[A@j+1L]
    ## Check for any zero-elements in remove.unused-columns:
    ok = !is.na(j.new)
    stack$A =
        sparseMatrix(i=A@i[ok]+1L,
                     j=j.new[ok],
                     x=A@x[ok],
                     dims=c(nrow(A), ncol.A))

    stack$effects$data = stack$effects$data[!remove,, drop=FALSE]
    stack$effects$nrow = ncol.A

    return(stack)
}

inla.stack.compress <- function(stack, remove.unused=TRUE)
{
    inla.require.inherits(stack, "inla.data.stack", "'stack'")

    if (stack$effects$nrow<2) {
        return(stack)
    }

    ii = do.call(order, as.list(stack$effects$data))
    jj.dupl =
        which(1L==
              diff(c(duplicated(stack$effects$data[ii,,drop=FALSE]),
                     FALSE)))
    kk.dupl =
        which(-1L==
              diff(c(duplicated(stack$effects$data[ii,,drop=FALSE]),
                     FALSE)))
    ## ii[jj.dupl] are the rows that have duplicates.
    ## ii[(jj.dupl[k]+1):kk.dupl[k]] are the duplicate rows for each k

    remove = rep(FALSE, stack$effects$nrow)
    index.new = rep(as.integer(NA), stack$effect$nrow)

    if (length(jj.dupl)>0) {
        for (k in 1:length(jj.dupl)) {
            i = ii[jj.dupl[k]]
            j = ii[(jj.dupl[k]+1):kk.dupl[k]]

            remove[j] = TRUE
            index.new[j] = i
        }
    }

    ncol.A = sum(!remove)
    if (ncol.A>0)
        index.new[!remove] = 1:ncol.A
    index.new[remove] = index.new[index.new[remove]]

    for (k in 1:length(stack$effects$index)) {
        stack$effects$index[[k]] = index.new[stack$effects$index[[k]]]
    }

    A = inla.as.dgTMatrix(stack$A)
    j.new = index.new[A@j+1L]
    ## Check for any zero-elements in remove.unused-columns:
    ok = !is.na(j.new)
    stack$A =
        sparseMatrix(i=A@i[ok]+1L,
                     j=j.new[ok],
                     x=A@x[ok],
                     dims=c(nrow(A), ncol.A))

    stack$effects$data = stack$effects$data[!remove,, drop=FALSE]
    stack$effects$nrow = ncol.A

    if (remove.unused) {
        return(inla.stack.remove.unused(stack))
    } else {
        return(stack)
    }
}




inla.stack <- function(..., compress=TRUE, remove.unused=TRUE)
{
    if (all(sapply(list(...), function(x) inherits(x, "inla.data.stack")))) {
        return(do.call(inla.stack.join,
                       c(list(...),
                         compress=compress,
                         remove.unused=remove.unused)))
    } else {
        return(do.call(inla.stack.sum,
                       c(list(...),
                         compress=compress,
                         remove.unused=remove.unused)))
    }
}


inla.stack.sum <- function(data, A, effects,
                           tag="",
                           compress=TRUE,
                           remove.unused=TRUE)
{
    input.nrow <- function(x) {
        return(inla.ifelse(is.matrix(x) || is(x, "Matrix"),
                           nrow(x),
                           inla.ifelse(is.data.frame(x),
                                       rep(nrow(x), ncol(x)),
                                       length(x))))
    }
    input.ncol <- function(x) {
        return(inla.ifelse(is.matrix(x) || is(x, "Matrix"),
                           ncol(x),
                           inla.ifelse(is.data.frame(x),
                                       rep(1L, ncol(x)),
                                       1L)))
    }

    input.list.nrow <- function(l) {
        if (is.data.frame(l))
            return(input.nrow(l))
        return(do.call(c, lapply(l, input.nrow)))
    }
    input.list.ncol <- function(l) {
        if (is.data.frame(l))
            return(input.ncol(l))
        return(do.call(c, lapply(l, input.ncol)))
    }
    input.list.names <- function(l) {
        if (is.data.frame(l))
            return(colnames(l))
        is.df = sapply(l, is.data.frame)
        name = vector("list", length(l))
        if (!is.null(names(l)))
            name[!is.df] =
                lapply(names(l)[!is.df],
                       function(x) list(x))
        else
            name[!is.df] = ""
        name[is.df] =
            lapply(l[is.df],
                   function(x) as.list(colnames(x)))

        return(do.call(c, name))
    }


    parse.input.list <- function(l, n.A, error.tag, tag="") {
        ncol = input.list.ncol(l)
        nrow = input.list.nrow(l)
        names = input.list.names(l)
        if ((n.A>1) && any(nrow==1)) {
            for (k in which(nrow==1)) {
                if (ncol[k]==1) {
                    l[[k]] = rep(l[[k]], n.A)
                    nrow[k] = n.A
                } else {
                    stop(paste(error.tag,
                               "Automatic expansion only available for scalars.",
                               sep=""))
                }
            }
        }

        if (length(unique(c(names, ""))) < length(c(names, ""))) {
            stop(paste(error.tag,
                       "All variables must have unique names\n",
                       "Names: ('",
                       paste(names, collapse="', '", sep=""),
                       "')",
                       sep=""))
        }

        for (k in 1:length(names)) {
            if (ncol[k]==1) {
                names(names)[k] = names[[k]][[1]]
                names[[k]] = c(names[[k]][[1]])
            } else {
                names(names)[k] = names[[k]][[1]]
                names[[k]] = paste(names[[k]][[1]], ".", 1:ncol[k], sep="")
            }
        }

        names(nrow) = names(names)
        names(ncol) = names(names)

        ## data = as.data.frame(do.call(cbind, l))
        data = as.data.frame(l)
        names(data) = do.call(c, names)
        nrow = nrow(data)
        if ((n.A>1) && (nrow != n.A)) {
            stop(paste(error.tag,
                       "Mismatching row sizes: ",
                       paste(nrow, collapse=",", sep=""),
                       ", n.A=", n.A,
                       sep=""))
        }

        index = list(1:nrow)
        if (!is.null(tag)) {
            names(index) = tag
        }

        info = list(data=data, nrow=nrow, ncol=ncol, names=names, index=index)
        class(info) = "inla.data.stack.info"

        return(info)
    }

    if (is.null(tag))
        stop("'tag' must not be 'NULL'")

    ## Check if only a single block was specified.
    if (!is.list(A)) {
        A = list(A)
        effects = list(effects)
    }
    if (length(A) != length(effects))
        stop(paste("length(A)=", length(A),
                   " should be equal to length(effects)=", length(effects), sep=""))

    n.effects = length(effects)

    eff = list()
    for (k in 1:n.effects) {
        if (is.data.frame(effects[[k]])) {
            eff[[k]] =
                parse.input.list(list(effects[[k]]),
                                 input.ncol(A[[k]]),
                                 paste("Effect block ", k, ":\n", sep=""),
                                 tag)
        } else {
            if (!is.list(effects[[k]])) {
                tmp =
                    inla.ifelse(is.null(names(effects)[k]),
                                "",
                                names(effects)[k])
                effects[[k]] = list(effects[[k]])
                names(effects[[k]]) = tmp
            }
            eff[[k]] =
                parse.input.list(effects[[k]],
                                 input.ncol(A[[k]]),
                                 paste("Effect block ", k, ":\n", sep=""),
                                 tag)
        }
    }

    for (k in 1:n.effects) {
        if (is.vector(A[[k]])) {
            A[[k]] = Matrix(A[[k]], input.nrow(A[[k]]), 1)
        }
        if ((input.ncol(A[[k]])==1) && (eff[[k]]$nrow>1)) {
            if (input.nrow(A[[k]])!=1)
                stop(paste("ncol(A) does not match nrow(effect) for block ",
                           k, ": ",
                           input.ncol(A[[k]]), " != ", eff[[k]]$nrow, sep=""))
            A[[k]] = Diagonal(eff[[k]]$nrow, A[[k]][1,1])
        } else if (input.ncol(A[[k]]) != eff[[k]]$nrow) {
            stop(paste("ncol(A) does not match nrow(effect) for block ",
                       k, ": ",
                       input.ncol(A[[k]]), " != ", eff[[k]]$nrow, sep=""))
        }
    }
    if (length(unique(input.list.nrow(A)))>1) {
        stop(paste("Row count mismatch for A: ",
                   paste(input.list.nrow(A), collapse=",", sep=""),
                   sep=""))
    }
    A.nrow = nrow(A[[1]])
    A.ncol = input.list.ncol(A)

    data =
        parse.input.list(inla.ifelse(is.data.frame(data),
                                     list(data),
                                     data),
                         A.nrow,
                         paste("Effect block ", k, ":\n", sep=""),
                         tag)

    effects = do.call(rbind.inla.data.stack.info, eff)

    A.matrix = do.call(cBind, A)
    A.nrow = nrow(A.matrix)
    A.ncol = ncol(A.matrix)

    if (length(unique(c(names(data$names), names(effects$names)))) <
        length(c(names(data$names), names(effects$names)))) {
        stop(paste("Names for data and effects must not coincide.\n",
                   "Data names:   ",
                   paste(names(data$names), collapse=", ", sep=""),
                   "\n",
                   "Effect names: ",
                   paste(names(effects$names), collapse=", ", sep=""),
                   sep=""))
    }

    stack = list(A=A.matrix, data=data, effects=effects)
    class(stack) = "inla.data.stack"

    if (compress) {
        return(inla.stack.compress(stack, remove.unused=remove.unused))
    } else if (remove.unused) {
        return(inla.stack.remove.unused(stack))
    } else {
        return(stack)
    }
}

inla.stack.join <- function(..., compress=TRUE, remove.unused=TRUE)
{
    S.input = list(...)

    data <- do.call(rbind.inla.data.stack.info,
                    lapply(S.input, function(x) x$data))
    effects <- do.call(rbind.inla.data.stack.info,
                       lapply(S.input, function(x) x$effects))
    A <- do.call(inla.dBind,
                 lapply(S.input, function(x) x$A))

    S.output = list(A=A, data=data, effects=effects)
    class(S.output) = "inla.data.stack"

    if (length(unique(c(names(data$names), names(effects$names)))) <
        length(c(names(data$names), names(effects$names)))) {
        stop(paste("Names for data and effects must not coincide.\n",
                   "Data names:   ",
                   paste(names(data$names), collapse=", ", sep=""),
                   "\n",
                   "Effect names: ",
                   paste(names(effects$names), collapse=", ", sep=""),
                   sep=""))
    }

    if (compress) {
        return(inla.stack.compress(S.output, remove.unused=remove.unused))
    } else if (remove.unused) {
        return(inla.stack.remove.unused(S.output))
    } else {
        return(S.output)
    }
}






inla.stack.index <- function(stack, tag)
{
    inla.require.inherits(stack, "inla.data.stack", "'stack'")

    if (is.null(tag)) {
        return(list(data=as.vector(do.call(c, stack$data$index)),
                    effects=(stack$data$nrow+
                             as.vector(do.call(c, stack$effects$index)))))
    } else {
        return(list(data=as.vector(do.call(c, stack$data$index[tag])),
                    effects=(stack$data$nrow+
                             as.vector(do.call(c, stack$effects$index[tag])))))
    }
}

inla.stack.do.extract <- function(dat)
{
    inla.require.inherits(dat, "inla.data.stack.info", "'dat'")

    handle.entry <- function(x)
    {
        if (dat$ncol[[x]]>1) {
            return(matrix(do.call(c,
                                  dat$data[dat$names[[x]]]),
                          dat$nrow,
                          dat$ncol[[x]]))
        } else if (is.factor(dat$data[[dat$names[[x]]]])) {
            return(dat$data[[dat$names[[x]]]])
        }
        return(as.vector(dat$data[[dat$names[[x]]]]))
    }

    out = lapply(names(dat$names), handle.entry)
    names(out) = names(dat$names)

    return(out)
}


inla.stack.LHS <- function(stack)
{
    inla.require.inherits(stack, "inla.data.stack", "'stack'")

    return(inla.stack.do.extract(stack$data))
}

inla.stack.RHS <- function(stack)
{
    inla.require.inherits(stack, "inla.data.stack", "'stack'")

    return(inla.stack.do.extract(stack$effects))
}

inla.stack.data <- function(stack, ...)
{
    inla.require.inherits(stack, "inla.data.stack", "'stack'")

    return(c(inla.stack.do.extract(stack$data),
             inla.stack.do.extract(stack$effects),
             list(...)))
}

inla.stack.A <- function(stack)
{
    inla.require.inherits(stack, "inla.data.stack", "'stack'")
    return(stack$A)
}
