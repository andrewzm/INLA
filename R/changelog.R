## Export: inla.changelog

##!\name{inla.changelog}
##!\alias{changelog}
##!\alias{inla.changelog}
##!\alias{inla.changes}
##!
##!\title{inla.changelog}
##!
##!\description{List the recent changes in the inla-program and its R-interface}
##!
##!\usage{
##!inla.changelog()
##!}
##!\author{Havard Rue \email{hrue@math.ntnu.no} }
##!\seealso{\code{\link{inla}}}

'inla.changelog' = function()
{
    browseURL("http://bitbucket.org/hrue/r-inla/commits/all")
    return (invisible())
}
