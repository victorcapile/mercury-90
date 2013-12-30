module orbital_elements

!*************************************************************
!** Modules that allow to get position from orbital elements
!** and the opposite. 
!** Version 1.0 - june 2011
!*************************************************************
  use types_numeriques

  implicit none
  
  contains

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

!      MCO_X2A.FOR    (ErikSoft   4 October 2000)

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

! Author: John E. Chambers

! Calculates an object's orbital semi-major axis given its Cartesian coords.

!------------------------------------------------------------------------------

subroutine mco_x2a (gm,x,y,z,u,v,w,a,r,v2)
  

  implicit none

  
  ! Input/Output
  real(double_precision),intent(in) :: gm,x,y,z,u,v,w
  real(double_precision),intent(out) :: a,r,v2
  
  !------------------------------------------------------------------------------
  
  r  = sqrt(x * x  +  y * y  +  z * z)
  v2 =      u * u  +  v * v  +  w * w
  a  = gm * r / (2.d0 * gm  -  r * v2)
  
  !------------------------------------------------------------------------------
  
  return
end subroutine mco_x2a

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

!      MCO_X2OV.FOR    (ErikSoft   20 February 2001)

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

! Author: John E. Chambers

! Calculates output variables for an object given its coordinates and
! velocities. The output variables are:
!  r = the radial distance
!  theta = polar angle
!  phi = azimuthal angle
!  fv = 1 / [1 + 2(ke/be)^2], where be and ke are the object's binding and
!                             kinetic energies. (Note that 0 < fv < 1).
!  vtheta = polar angle of velocity vector
!  vphi = azimuthal angle of the velocity vector

!------------------------------------------------------------------------------

subroutine mco_x2ov (rcen,mcen,m,x,y,z,u,v,w,fr,theta,phi,fv,vtheta,vphi)
  
  use physical_constant
  use mercury_constant
  use mercury_globals

  implicit none

  
  ! Input/Output
  real(double_precision) :: rcen,mcen,m,x,y,z,u,v,w,fr,theta,phi,fv,vtheta,vphi
  
  ! Local
  real(double_precision) :: r,v2,v1,be,ke,temp
  
  !------------------------------------------------------------------------------
  
  r = sqrt(x*x + y*y + z*z)
  v2 =     u*u + v*v + w*w
  v1 = sqrt(v2)
  be = (mcen + m) / r
  ke = .5d0 * v2
  
  fr = log10 (min(max(r, rcen), rmax) / rcen)
  temp = ke / be
  fv = 1.d0 / (1.d0 + 2.d0*temp*temp)
  
  theta  = mod (acos (z / r) + TWOPI, TWOPI)
  vtheta = mod (acos (w / v1) + TWOPI, TWOPI)
  phi  = mod (atan2 (y, x) + TWOPI, TWOPI)
  vphi = mod (atan2 (v, u) + TWOPI, TWOPI)
  
  !------------------------------------------------------------------------------
  
  return
end subroutine mco_x2ov

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

!      MCO_X2EL.FOR    (ErikSoft  23 January 2001)

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

! Author: John E. Chambers

! Calculates Keplerian orbital elements given relative coordinates and
! velocities, and GM = G times the sum of the masses.

! The elements are: q = perihelion distance
!                   e = eccentricity
!                   i = inclination
!                   p = longitude of perihelion (NOT argument of perihelion!!)
!                   n = longitude of ascending node
!                   l = mean anomaly (or mean longitude if e < 1.e-8)

!------------------------------------------------------------------------------

subroutine mco_x2el (gm,x,y,z,u,v,w,q,e,i,p,n,l)
  
  use physical_constant
  use mercury_constant

  implicit none

  
  ! Input/Output
  real(double_precision),intent(in) :: gm,x,y,z,u,v,w
  real(double_precision),intent(out) :: q,e,i,p,n,l
  
  ! Local
  real(double_precision) :: hx,hy,hz,h2,h,v2,r,rv,s,true
  real(double_precision) :: ci,to,temp,tmp2,bige,f,cf,ce
  
  !------------------------------------------------------------------------------
  
  hx = y * w  -  z * v
  hy = z * u  -  x * w
  hz = x * v  -  y * u
  h2 = hx*hx + hy*hy + hz*hz
  v2 = u * u  +  v * v  +  w * w
  rv = x * u  +  y * v  +  z * w
  r = sqrt(x*x + y*y + z*z)
  h = sqrt(h2)
  s = h2 / gm
  
  ! Inclination and node
  ci = hz / h
  if (abs(ci).lt.1) then
     i = acos (ci)
     n = atan2 (hx,-hy)
     if (n.lt.0) n = n + TWOPI
  else
     if (ci.gt.0) i = 0.d0
     if (ci.lt.0) i = PI
     n = 0.d0
  end if
  
  ! Eccentricity and perihelion distance
  temp = 1.d0  +  s * (v2 / gm  -  2.d0 / r)
  if (temp.le.0) then
     e = 0.d0
  else
     e = sqrt (temp)
  end if
  q = s / (1.d0 + e)
  
  ! True longitude
  if (hy.ne.0) then
     to = -hx/hy
     temp = (1.d0 - ci) * to
     tmp2 = to * to
     true = atan2((y*(1.d0+tmp2*ci)-x*temp),(x*(tmp2+ci)-y*temp))
  else
     true = atan2(y * ci, x)
  end if
  if (ci.lt.0) true = true + PI
  
  if (e.lt.3.d-8) then
     p = 0.d0
     l = true
  else
     ce = (v2*r - gm) / (e*gm)
     
     ! Mean anomaly for ellipse
     if (e.lt.1) then
        if (abs(ce).gt.1) ce = sign(1.d0,ce)
        bige = acos(ce)
        if (rv.lt.0) bige = TWOPI - bige
        l = bige - e*sin(bige)
     else
        
        ! Mean anomaly for hyperbola
        if (ce.lt.1) ce = 1.d0
        bige = log( ce + sqrt(ce*ce-1.d0) )
        if (rv.lt.0) bige = - bige
        l = e*sinh(bige) - bige
     end if
     
     ! Longitude of perihelion
     cf = (s - r) / (e*r)
     if (abs(cf).gt.1) cf = sign(1.d0,cf)
     f = acos(cf)
     if (rv.lt.0) f = TWOPI - f
     p = true - f
     p = mod (p + TWOPI + TWOPI, TWOPI)
  end if
  
  if (l.lt.0) l = l + TWOPI
  if (l.gt.TWOPI) l = mod (l, TWOPI)
  
  !------------------------------------------------------------------------------
  
  return
end subroutine mco_x2el

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

!      MCO_X2AE.FOR    (17 august 2011)

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

! Author: C. Cossou

! Calculates Keplerian orbital elements and motion properties given relative coordinates and
! velocities, and GM = G times the sum of the masses.

! The elements are: a = semi major axis (in AU)
!                   e = eccentricity
!                   i = inclination (in rad)
!                   r = the orbital distance of the planet from the star [AU]
!                   v2 = the norm of the velocity squared [AU^2/day^2]
!                   h = the angular momentum? [I don't know where the mass is]
!                   
! REMARKS : the orbital parameters, especially the eccentricity and the semi major axis are not retrieved correctly when I set 
! manually the position and the velocity (i.e only position(1) and velocity(2), the rest to 0), I don't know why.
!------------------------------------------------------------------------------

subroutine mco_x2ae (gm,x,y,z,u,v,w,a,e,i,r,v2,h)
  
  use physical_constant
  use mercury_constant

  implicit none

  
  ! Input/Output
  real(double_precision),intent(in) :: gm,x,y,z,u,v,w
  real(double_precision),intent(out) :: a,e,i,r,v2,h
  
  ! Local
  real(double_precision) :: hx,hy,hz,h2,rv,s
  real(double_precision) :: ci,temp
  
  !------------------------------------------------------------------------------
  
  hx = y * w  -  z * v
  hy = z * u  -  x * w
  hz = x * v  -  y * u
  h2 = hx*hx + hy*hy + hz*hz
  v2 = u * u  +  v * v  +  w * w
  rv = x * u  +  y * v  +  z * w
  r = sqrt(x*x + y*y + z*z)
  h = sqrt(h2)
  s = h2 / gm
  


  
  ! Inclination and node
  ci = hz / h
  if (abs(ci).lt.1) then
     i = acos (ci)
  else
     if (ci.gt.0) i = 0.d0
     if (ci.lt.0) i = PI
  end if
  
  ! Eccentricity and perihelion distance
  temp = 1.d0  +  s * (v2 / gm  -  2.d0 / r)
  if (temp.le.0) then
     e = 0.d0
  else
     e = sqrt (temp)
  end if

  ! semi major axis
!~   a  = gm * r / (2.d0 * gm - r * v2) ! this was the formulae given in the mco_x2a but problems occurs sometimes
  a = s / (1.d0 - e*e)
  
  ! In case of collision or any situation where orbits are no longer keplerian, we don't want to get negative values of 'a'. 
  ! Instead, we will use the instantaneous position as semi major axis.
!~   if (a.lt.0.) then
!~     a = r
!~   end if
!~   
!~   if (e.lt.1.d0) then ! This one seems not to be accurate when e vary a lot. 
!~     a = s / (1.d0 - e*e)
!~   else
!~     a = s / (e*e - 1.d0)
!~   end if
!~   
!~   if (e.lt.1.d0) then
!~     a = gm * r / (2.d0 * gm - r * v2)
!~   else
!~     a = gm * r / (r * v2 - 2.d0 * gm)
!~   end if
  !------------------------------------------------------------------------------
  
!~   if (e.gt.0.99) then
!~     write(*,*) a, e, i, r, v2, h
!~   end if
!~   write(*,*) a, e, i, r, v2, h
  return
end subroutine mco_x2ae

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

!      MCO_EL2X.FOR    (ErikSoft  7 July 1999)

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

! Author: John E. Chambers

! Calculates Cartesian coordinates and velocities given Keplerian orbital
! elements (for elliptical, parabolic or hyperbolic orbits).

! Based on a routine from Levison and Duncan's SWIFT integrator.

!  gm = grav const * (central + secondary mass)
!  q = perihelion distance
!  e = eccentricity
!  i = inclination                 )
!  p = longitude of perihelion !!! )   in
!  n = longitude of ascending node ) radians
!  l = mean anomaly                )

!  x,y,z = Cartesian positions  ( units the same as a )
!  u,v,w =     "     velocities ( units the same as sqrt(gm/a) )

!------------------------------------------------------------------------------

subroutine mco_el2x (gm,q,e,i,p,n,l,x,y,z,u,v,w)
  
  use physical_constant
  use mercury_constant
  use kepler_equation
  use utilities, only : mco_sine

  implicit none
  
  ! Input/Output
  real(double_precision), intent(in) :: gm
  real(double_precision), intent(in) :: q
  real(double_precision), intent(in) :: e
  real(double_precision), intent(inout) :: i
  real(double_precision), intent(in) :: p
  real(double_precision), intent(inout) :: n
  real(double_precision), intent(in) :: l
  real(double_precision), intent(out) :: x,y,z,u,v,w
  
  ! Local
  real(double_precision) :: g,a,ci,si,cn,sn,cg,sg,ce,se,romes,temp
  real(double_precision) :: z1,z2,z3,z4,d11,d12,d13,d21,d22,d23
  
  !------------------------------------------------------------------------------
  
  ! Change from longitude of perihelion to argument of perihelion
  g = p - n
  
  ! Rotation factors
  call mco_sine (i,si,ci)
  call mco_sine (g,sg,cg)
  call mco_sine (n,sn,cn)
  z1 = cg * cn
  z2 = cg * sn
  z3 = sg * cn
  z4 = sg * sn
  d11 =  z1 - z4*ci
  d12 =  z2 + z3*ci
  d13 = sg * si
  d21 = -z3 - z2*ci
  d22 = -z4 + z1*ci
  d23 = cg * si
  
  ! Semi-major axis
  a = q / (1.d0 - e)
  
  ! Ellipse
  if (e.lt.1.d0) then
     romes = sqrt(1.d0 - e*e)
     temp = mco_kep (e,l)
!~      se = sin(temp)
!~      ce = cos(temp)
     call mco_sine (temp,se,ce)
     z1 = a * (ce - e)
     z2 = a * romes * se
     temp = sqrt(gm/a) / (1.d0 - e*ce)
     z3 = -se * temp
     z4 = romes * ce * temp
  else
     ! Parabola
     if (e.eq.1.d0) then
        ce = orbel_zget(l)
        z1 = q * (1.d0 - ce*ce)
        z2 = 2.d0 * q * ce
        z4 = sqrt(2.d0*gm/q) / (1.d0 + ce*ce)
        z3 = -ce * z4
     else
        ! Hyperbola
        romes = sqrt(e*e - 1.d0)
        temp = orbel_fhybrid(e,l)
        se = sinh(temp)
        ce = cosh(temp)
!~         call mco_sinh (temp,se,ce)
        z1 = a * (ce - e)
        z2 = -a * romes * se
        temp = sqrt(gm/abs(a)) / (e*ce - 1.d0)
        z3 = -se * temp
        z4 = romes * ce * temp
     end if
  endif
  
  x = d11 * z1  +  d21 * z2
  y = d12 * z1  +  d22 * z2
  z = d13 * z1  +  d23 * z2
  u = d11 * z3  +  d21 * z4
  v = d12 * z3  +  d22 * z4
  w = d13 * z3  +  d23 * z4
  
  !------------------------------------------------------------------------------
  
  return
end subroutine mco_el2x

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

!      MCO_OV2X.FOR    (ErikSoft   28 February 2001)

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

! Author: John E. Chambers

! Converts output variables for an object to coordinates and velocities.
! The output variables are:
!  r = the radial distance
!  theta = polar angle
!  phi = azimuthal angle
!  fv = 1 / [1 + 2(ke/be)^2], where be and ke are the object's binding and
!                             kinetic energies. (Note that 0 < fv < 1).
!  vtheta = polar angle of velocity vector
!  vphi = azimuthal angle of the velocity vector

!------------------------------------------------------------------------------

subroutine mco_ov2x (rcen,mcen,m,fr,theta,phi,fv,vtheta,vphi,x,y,z,u,v,w)
  
  use physical_constant
  use mercury_constant

  implicit none

  
  ! Input/Output
  real(double_precision), intent(in) :: rcen,mcen,m,fr,theta,phi,fv,vtheta,vphi
  real(double_precision), intent(out) :: x,y,z,u,v,w
  
  ! Local
  real(double_precision) :: r,v1,temp
  
  !------------------------------------------------------------------------------
  
  r = rcen * 10.d0**fr
  temp = sqrt(.5d0*(1.d0/fv - 1.d0))
  v1 = sqrt(2.d0 * temp * (mcen + m) / r)
  
  x = r * sin(theta) * cos(phi)
  y = r * sin(theta) * sin(phi)
  z = r * cos(theta)
  u = v1 * sin(vtheta) * cos(vphi)
  v = v1 * sin(vtheta) * sin(vphi)
  w = v1 * cos(vtheta)
  
  !------------------------------------------------------------------------------
  
  return
end subroutine mco_ov2x


end module orbital_elements
