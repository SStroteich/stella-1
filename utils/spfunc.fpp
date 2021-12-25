# include "define.inc"

!
! special function wrapper routine written by Tomo Tatsuno (5/7/08)
! only has Bessel function at the moment
!
! RN 2008/07/01: Error function is added
! RN 2008/07/01: Compilers not having intrinsic those special functions
!                must choose one of the following
!                 1: local [USE_LOCAL_SPFUNC=on]
!                 2: NAG Library [USE_NAGLIB=spfunc]
!
! Unfortunately we do not support elemental feature for ifort...
! XL-fortran does not seem to have intrinsic Bessel function
!
! To do: avoid explicit specification of kind and use kind_rs or kind_rd
!        support of other compilers such as absoft, lahay etc...
!
! PGI cannot use kind_rs, kind_rd as kind specifications, but it is ok
! because we know kind_rs=4 kind_rd=8 for PGI
!

module spfunc
   use constants, only: kind_rs, kind_rd
# if SPFUNC == _SPNAG_
   use constants, only: nag_kind
# endif

   implicit none

   public :: j0, j1
   public :: erf_ext

   private

# if SPFUNC == _SPNAG_

   ! error handling
   ! ifail=0: terminate the program
   ! ifail=1 (-1): continues the program w/o (w) error messages
   integer :: ifail = -1

# endif

# if SPFUNC == _SPLOCAL_
# elif SPFUNC == _SPNAG_
# else /* if not _SPLOCAL_ and not _SPNAG_ */
# if (FCOMPILER == _GFORTRAN_ || FCOMPILER == _INTEL_ \
   ||FCOMPILER == _PATHSCALE_)

   interface j0
      module procedure sj0, dj0
   end interface
   interface j1
      module procedure sj1, dj1
   end interface
   interface erf_ext
      module procedure serf_ext, derf_ext
   end interface

# elif FCOMPILER == _G95_ /* not _GFORTRAN_, _INTEL_, _PATHSCALE_ */

   interface j0
      module procedure sj0, dj0
   end interface
   interface j1
      module procedure sj1, dj1
   end interface

# elif FCOMPILER == _PGI_ /* not _GFORTRAN_, _INTEL_, _PATHSCALE_, _G95_ */

   interface j0
      elemental function besj0(x)
         real(kind=4), intent(in) :: x
         real(kind=4) :: besj0
      end function besj0
      elemental function dbesj0(x)
         real(kind=8), intent(in) :: x
         real(kind=8) :: dbesj0
      end function dbesj0
   end interface
   ! j1 is below

   interface erf_ext
      elemental function erf(x)
         real(kind=4), intent(in) :: x
         real(kind=4) :: erf
      end function erf
      elemental function derf(x)
         real(kind=8), intent(in) :: x
         real(kind=8) :: derf
      end function derf
   end interface

# endif /* FCOMPILER */
# endif /* SPFUNC */

contains

# if SPFUNC == _SPLOCAL_

   !-------------------------------------------------------------------------!
   ! double precision Bessel functions (dbesj0.f dbesj1.f)                   !
   ! http://www.kurims.kyoto-u.ac.jp/~ooura/bessel.html                      !
   !-------------------------------------------------------------------------!
   ! Copyright(C) 1996 Takuya OOURA (email: ooura@mmm.t.u-tokyo.ac.jp).      !
   ! You may use, copy, modify this code for any purpose and                 !
   ! without fee. You may distribute this ORIGINAL package.                  !
   !-------------------------------------------------------------------------!
   ! Modified by Ryusuke NUMATA 2008/06/27                                   !
   !  to fit F90 format, and for j1 to give besj1/x                          !
   !-------------------------------------------------------------------------!

   ! these routines are declared as real, but can be promoted to
   ! double presicion using compiler option.
   ! this is so because constatns used are only double precision,
   ! and cannot be promoted to quad-precision.

   ! differences from GNU gfortran besj0 and besj1 are
   ! |err| < 1.e-15

   elemental function j0(x)

      ! Bessel J_0(x) function in double precision
      use constants, only: pi
      real :: j0
      real, intent(in) :: x
      integer :: k
      real :: w, t, y, theta, v

      real, parameter :: a(0:7) = (/ &
           & -0.0000000000023655394, 0.0000000004708898680, &
           & -0.0000000678167892231, 0.0000067816840038636, &
           & -0.0004340277777716935, 0.0156249999999992397, &
           & -0.2499999999999999638, 0.9999999999999999997/)

      real, parameter :: b(0:64) = (/ &
           &  0.0000000000626681117, -0.0000000022270614428, &
           &  0.0000000662981656302, -0.0000016268486502196, &
           &  0.0000321978384111685, -0.0005005237733315830, &
           &  0.0059060313537449816, -0.0505265323740109701, &
           &  0.2936432097610503985, -1.0482565081091638637, &
           &  1.9181123286040428113, -1.1319199475221700100, &
           & -0.1965480952704682000, 0.0000000000457457332, &
           & -0.0000000015814772025, 0.0000000455487446311, &
           & -0.0000010735201286233, 0.0000202015179970014, &
           & -0.0002942392368203808, 0.0031801987726150648, &
           & -0.0239875209742846362, 0.1141447698973777641, &
           & -0.2766726722823530233, 0.1088620480970941648, &
           &  0.5136514645381999197, -0.2100594022073706033, &
           &  0.0000000000331366618, -0.0000000011119090229, &
           &  0.0000000308823040363, -0.0000006956602653104, &
           &  0.0000123499947481762, -0.0001662951945396180, &
           &  0.0016048663165678412, -0.0100785479932760966, &
           &  0.0328996815223415274, -0.0056168761733860688, &
           & -0.2341096400274429386, 0.2551729256776404262, &
           &  0.2288438186148935667, 0.0000000000238007203, &
           & -0.0000000007731046439, 0.0000000206237001152, &
           & -0.0000004412291442285, 0.0000073107766249655, &
           & -0.0000891749801028666, 0.0007341654513841350, &
           & -0.0033303085445352071, 0.0015425853045205717, &
           &  0.0521100583113136379, -0.1334447768979217815, &
           & -0.1401330292364750968, 0.2685616168804818919, &
           &  0.0000000000169355950, -0.0000000005308092192, &
           &  0.0000000135323005576, -0.0000002726650587978, &
           &  0.0000041513240141760, -0.0000443353052220157, &
           &  0.0002815740758993879, -0.0004393235121629007, &
           & -0.0067573531105799347, 0.0369141914660130814, &
           &  0.0081673361942996237, -0.2573381285898881860, &
           &  0.0459580257102978932/)

      real, parameter :: c(0:69) = (/ &
           & -0.00000000003009451757, -0.00000000014958003844, &
           &  0.00000000506854544776, 0.00000001863564222012, &
           & -0.00000060304249068078, -0.00000147686259937403, &
           &  0.00004714331342682714, 0.00006286305481740818, &
           & -0.00214137170594124344, -0.00089157336676889788, &
           &  0.04508258728666024989, -0.00490362805828762224, &
           & -0.27312196367405374426, 0.04193925184293450356, &
           & -0.00000000000712453560, -0.00000000041170814825, &
           &  0.00000000138012624364, 0.00000005704447670683, &
           & -0.00000019026363528842, -0.00000533925032409729, &
           &  0.00001736064885538091, 0.00030692619152608375, &
           & -0.00092598938200644367, -0.00917934265960017663, &
           &  0.02287952522866389076, 0.10545197546252853195, &
           & -0.16126443075752985095, -0.19392874768742235538, &
           &  0.00000000002128344556, -0.00000000031053910272, &
           & -0.00000000334979293158, 0.00000004507232895050, &
           &  0.00000036437959146427, -0.00000446421436266678, &
           & -0.00002523429344576552, 0.00027519882931758163, &
           &  0.00097185076358599358, -0.00898326746345390692, &
           & -0.01665959196063987584, 0.11456933464891967814, &
           &  0.07885001422733148815, -0.23664819446234712621, &
           &  0.00000000003035295055, 0.00000000005486066835, &
           & -0.00000000501026824811, -0.00000000501246847860, &
           &  0.00000058012340163034, 0.00000016788922416169, &
           & -0.00004373270270147275, 0.00001183898532719802, &
           &  0.00189863342862291449, -0.00113759249561636130, &
           & -0.03846797195329871681, 0.02389746880951420335, &
           &  0.22837862066532347461, -0.06765394811166522844, &
           &  0.00000000001279875977, 0.00000000035925958103, &
           & -0.00000000228037105967, -0.00000004852770517176, &
           &  0.00000028696428000189, 0.00000440131125178642, &
           & -0.00002366617753349105, -0.00024412456252884129, &
           &  0.00113028178539430542, 0.00708470513919789080, &
           & -0.02526914792327618386, -0.08006137953480093426, &
           &  0.16548380461475971846, 0.14688405470042110229/)

      real, parameter :: d(0:51) = (/ &
           &  1.059601355592185731e-14, -2.71150591218550377e-13,   &
           &  8.6514809056201638e-12, -4.6264028554286627e-10,    &
           &  5.0815403835647104e-8, -1.76722552048141208e-5,    &
           &  0.16286750396763997378, 2.949651820598278873e-13,  &
           & -8.818215611676125741e-12, 3.571119876162253451e-10,  &
           & -2.631924120993717060e-8, 4.709502795656698909e-6,   &
           & -5.208333333333283282e-3, 7.18344107717531977e-15,   &
           & -2.51623725588410308e-13, 8.6017784918920604e-12,    &
           & -4.6256876614290359e-10, 5.0815343220437937e-8,     &
           & -1.76722551764941970e-5, 0.16286750396763433767,    &
           &  2.2327570859680094777e-13, -8.464594853517051292e-12,  &
           &  3.563766464349055183e-10, -2.631843986737892965e-8,   &
           &  4.709502342288659410e-6, -5.2083333332278466225e-3,  &
           &  5.15413392842889366e-15, -2.27740238380640162e-13,   &
           &  8.4827767197609014e-12, -4.6224753682737618e-10,    &
           &  5.0814848128929134e-8, -1.76722547638767480e-5,    &
           &  0.16286750396748926663, 1.7316195320192170887e-13, &
           & -7.971122772293919646e-12, 3.544039469911895749e-10,  &
           & -2.631443902081701081e-8, 4.709498228695400603e-6,   &
           & -5.2083333315143653610e-3, 3.84653681453798517e-15,   &
           & -2.04464520778789011e-13, 8.3089298605177838e-12,    &
           & -4.6155016158412096e-10, 5.0813263696466650e-8,     &
           & -1.76722528311426167e-5, 0.16286750396650065930,    &
           &  1.3797879972460878797e-13, -7.448089381011684812e-12,  &
           &  3.512733797106959780e-10, -2.630500895563592722e-8,   &
           &  4.709483934775839193e-6, -5.2083333227940760113e-3/)

      w = abs(x)
      if (w < 1) then
         t = w * w
         y = ((((((a(0) * t + a(1)) * t + &
              & a(2)) * t + a(3)) * t + a(4)) * t + &
              & a(5)) * t + a(6)) * t + a(7)
      else if (w < 8.5) then
         t = w * w * 0.0625
         k = int(t)
         t = t - (k + 0.5)
         k = k * 13
         y = (((((((((((b(k) * t + b(k + 1)) * t + &
              & b(k + 2)) * t + b(k + 3)) * t + b(k + 4)) * t + &
              & b(k + 5)) * t + b(k + 6)) * t + b(k + 7)) * t + &
              & b(k + 8)) * t + b(k + 9)) * t + b(k + 10)) * t + &
              & b(k + 11)) * t + b(k + 12)
      else if (w < 12.5) then
         k = int(w)
         t = w - (k + 0.5)
         k = 14 * (k - 8)
         y = ((((((((((((c(k) * t + c(k + 1)) * t + &
              & c(k + 2)) * t + c(k + 3)) * t + c(k + 4)) * t + &
              & c(k + 5)) * t + c(k + 6)) * t + c(k + 7)) * t + &
              & c(k + 8)) * t + c(k + 9)) * t + c(k + 10)) * t + &
              & c(k + 11)) * t + c(k + 12)) * t + c(k + 13)
      else
         v = 24./w
         t = v * v
         k = 13 * (int(t))
         y = ((((((d(k) * t + d(k + 1)) * t + &
              & d(k + 2)) * t + d(k + 3)) * t + d(k + 4)) * t + &
              & d(k + 5)) * t + d(k + 6)) * sqrt(v)
         theta = (((((d(k + 7) * t + d(k + 8)) * t + &
              & d(k + 9)) * t + d(k + 10)) * t + d(k + 11)) * t + &
              & d(k + 12)) * v - .25 * pi
         y = y * cos(w + theta)
      end if
      j0 = y
   end function j0

   elemental function j1(x)

      ! Bessel J_1(x) function devided by x in double precision
      use constants, only: pi
      real :: j1
      real, intent(in) :: x
      integer :: k
      real :: w, t, y, theta, v

      real, parameter :: a(0:7) = (/ &
           & -0.00000000000014810349, 0.00000000003363594618, &
           & -0.00000000565140051697, 0.00000067816840144764, &
           & -0.00005425347222188379, 0.00260416666666662438, &
           & -0.06249999999999999799, 0.49999999999999999998/)
      real, parameter :: b(0:64) = (/ &
           &  0.00000000000243721316, -0.00000000009400554763,  &
           &  0.00000000306053389980, -0.00000008287270492518,  &
           &  0.00000183020515991344, -0.00003219783841164382,  &
           &  0.00043795830161515318, -0.00442952351530868999,  &
           &  0.03157908273375945955, -0.14682160488052520107,  &
           &  0.39309619054093640008, -0.47952808215101070280,  &
           &  0.14148999344027125140, 0.00000000000182119257,  &
           & -0.00000000006862117678, 0.00000000217327908360,  &
           & -0.00000005693592917820, 0.00000120771046483277,  &
           & -0.00002020151799736374, 0.00025745933218048448,  &
           & -0.00238514907946126334, 0.01499220060892984289,  &
           & -0.05707238494868888345, 0.10375225210588234727,  &
           & -0.02721551202427354117, -0.06420643306727498985,  &
           &  0.000000000001352611196, -0.000000000049706947875, &
           &  0.000000001527944986332, -0.000000038602878823401, &
           &  0.000000782618036237845, -0.000012349994748451100, &
           &  0.000145508295194426686, -0.001203649737425854162, &
           &  0.006299092495799005109, -0.016449840761170764763, &
           &  0.002106328565019748701, 0.058527410006860734650, &
           & -0.031896615709705053191, 0.000000000000997982124, &
           & -0.000000000035702556073, 0.000000001062332772617, &
           & -0.000000025779624221725, 0.000000496382962683556, &
           & -0.000007310776625173004, 0.000078028107569541842, &
           & -0.000550624088538081113, 0.002081442840335570371, &
           & -0.000771292652260286633, -0.019541271866742634199, &
           &  0.033361194224480445382, 0.017516628654559387164, &
           &  0.000000000000731050661, -0.000000000025404499912, &
           &  0.000000000729360079088, -0.000000016915375004937, &
           &  0.000000306748319652546, -0.000004151324014331739, &
           &  0.000038793392054271497, -0.000211180556924525773, &
           &  0.000274577195102593786, 0.003378676555289966782, &
           & -0.013842821799754920148, -0.002041834048574905921, &
           &  0.032167266073736023299/)

      real, parameter :: c(0:69) = (/ &
           & -0.00000000001185964494, 0.00000000039110295657, &
           &  0.00000000180385519493, -0.00000005575391345723, &
           & -0.00000018635897017174, 0.00000542738239401869, &
           &  0.00001181490114244279, -0.00033000319398521070, &
           & -0.00037717832892725053, 0.01070685852970608288, &
           &  0.00356629346707622489, -0.13524776185998074716, &
           &  0.00980725611657523952, 0.27312196367405374425, &
           & -0.00000000003029591097, 0.00000000009259293559, &
           &  0.00000000496321971223, -0.00000001518137078639, &
           & -0.00000057045127595547, 0.00000171237271302072, &
           &  0.00004271400348035384, -0.00012152454198713258, &
           & -0.00184155714921474963, 0.00462994691003219055, &
           &  0.03671737063840232452, -0.06863857568599167175, &
           & -0.21090395092505707655, 0.16126443075752985095, &
           & -0.00000000002197602080, -0.00000000027659100729, &
           &  0.00000000374295124827, 0.00000003684765777023, &
           & -0.00000045072801091574, -0.00000327941630669276, &
           &  0.00003571371554516300, 0.00017664005411843533, &
           & -0.00165119297594774104, -0.00485925381792986774, &
           &  0.03593306985381680131, 0.04997877588191962563, &
           & -0.22913866929783936544, -0.07885001422733148814, &
           &  0.00000000000516292316, -0.00000000039445956763, &
           & -0.00000000066220021263, 0.00000005511286218639, &
           &  0.00000005012579400780, -0.00000522111059203425, &
           & -0.00000134311394455105, 0.00030612891890766805, &
           & -0.00007103391195326182, -0.00949316714311443491, &
           &  0.00455036998246516948, 0.11540391585989614784, &
           & -0.04779493761902840455, -0.22837862066532347460, &
           &  0.00000000002697817493, -0.00000000016633326949, &
           & -0.00000000433134860350, 0.00000002508404686362, &
           &  0.00000048528284780984, -0.00000258267851112118, &
           & -0.00003521049080466759, 0.00016566324273339952, &
           &  0.00146474737522491617, -0.00565140892697147306, &
           & -0.02833882055679300400, 0.07580744376982855057, &
           &  0.16012275906960187978, -0.16548380461475971845/)

      real, parameter :: d(0:51) = (/ &
           & -1.272346002224188092e-14, 3.370464692346669075e-13, &
           & -1.144940314335484869e-11, 6.863141561083429745e-10, &
           & -9.491933932960924159e-8, 5.301676561445687562e-5,  &
           &  0.1628675039676399740, -3.652982212914147794e-13, &
           &  1.151126750560028914e-11, -5.165585095674343486e-10, &
           &  4.657991250060549892e-8, -1.186794704692706504e-5,  &
           &  1.562499999999994026e-2, -8.713069680903981555e-15, &
           &  3.140780373478474935e-13, -1.139089186076256597e-11, &
           &  6.862299023338785566e-10, -9.491926788274594674e-8,  &
           &  5.301676558106268323e-5, 0.1628675039676466220,    &
           & -2.792555727162752006e-13, 1.108650207651756807e-11, &
           & -5.156745588549830981e-10, 4.657894859077370979e-8,  &
           & -1.186794650130550256e-5, 1.562499999987299901e-2,  &
           & -6.304859171204770696e-15, 2.857249044208791652e-13, &
           & -1.124956921556753188e-11, 6.858482894906716661e-10, &
           & -9.491867953516898460e-8, 5.301676509057781574e-5,  &
           &  0.1628675039678191167, -2.185193490132496053e-13, &
           &  1.048820673697426074e-11, -5.132819367467680132e-10, &
           &  4.657409437372994220e-8, -1.186794150862988921e-5,  &
           &  1.562499999779270706e-2, -4.740417209792009850e-15, &
           &  2.578715253644144182e-13, -1.104148898414138857e-11, &
           &  6.850134201626289183e-10, -9.491678234174919640e-8,  &
           &  5.301676277588728159e-5, 0.1628675039690033136,    &
           & -1.755122057493842290e-13, 9.848723331445182397e-12, &
           & -5.094535425482245697e-10, 4.656255982268609304e-8,  &
           & -1.186792402114394891e-5, 1.562499998712198636e-2/)

      w = abs(x)
      if (w < 1) then
         t = w * w
!       y = (((((((a(0) * t + a(1)) * t + &
!            & a(2)) * t + a(3)) * t + a(4)) * t + &
!            & a(5)) * t + a(6)) * t + a(7)) * w
         y = ((((((a(0) * t + a(1)) * t + &
              & a(2)) * t + a(3)) * t + a(4)) * t + &
              & a(5)) * t + a(6)) * t + a(7)
      else if (w < 8.5) then
         t = w * w * 0.0625
         k = int(t)
         t = t - (k + 0.5)
         k = k * 13
!       y = ((((((((((((b(k) * t + b(k + 1)) * t + &
!            & b(k + 2)) * t + b(k + 3)) * t + b(k + 4)) * t + &
!            & b(k + 5)) * t + b(k + 6)) * t + b(k + 7)) * t + &
!            & b(k + 8)) * t + b(k + 9)) * t + b(k + 10)) * t + &
!            & b(k + 11)) * t + b(k + 12)) * w
         y = (((((((((((b(k) * t + b(k + 1)) * t + &
              & b(k + 2)) * t + b(k + 3)) * t + b(k + 4)) * t + &
              & b(k + 5)) * t + b(k + 6)) * t + b(k + 7)) * t + &
              & b(k + 8)) * t + b(k + 9)) * t + b(k + 10)) * t + &
              & b(k + 11)) * t + b(k + 12)
      else if (w < 12.5) then
         k = int(w)
         t = w - (k + 0.5)
         k = 14 * (k - 8)
!       y = ((((((((((((c(k) * t + c(k + 1)) * t + &
!            & c(k + 2)) * t + c(k + 3)) * t + c(k + 4)) * t + &
!            & c(k + 5)) * t + c(k + 6)) * t + c(k + 7)) * t + &
!            & c(k + 8)) * t + c(k + 9)) * t + c(k + 10)) * t + &
!            & c(k + 11)) * t + c(k + 12)) * t + c(k + 13)
         y = (((((((((((((c(k) * t + c(k + 1)) * t + &
              & c(k + 2)) * t + c(k + 3)) * t + c(k + 4)) * t + &
              & c(k + 5)) * t + c(k + 6)) * t + c(k + 7)) * t + &
              & c(k + 8)) * t + c(k + 9)) * t + c(k + 10)) * t + &
              & c(k + 11)) * t + c(k + 12)) * t + c(k + 13)) / w
      else
         v = 24./w
         t = v * v
         k = 13 * (int(t))
         y = ((((((d(k) * t + d(k + 1)) * t + &
              & d(k + 2)) * t + d(k + 3)) * t + d(k + 4)) * t + &
              & d(k + 5)) * t + d(k + 6)) * sqrt(v)
         theta = (((((d(k + 7) * t + d(k + 8)) * t + &
              & d(k + 9)) * t + d(k + 10)) * t + d(k + 11)) * t + &
              & d(k + 12)) * v - .25 * pi
         y = y * sin(w + theta)
!
         y = y / w
      end if
!    if (x < 0) y = -y
      j1 = y
   end function j1

   !-------------------------------------------------------------------------!
   ! double precision error functions (derf.f)                               !
   ! http://www.kurims.kyoto-u.ac.jp/~ooura/gamerf.html                      !
   !-------------------------------------------------------------------------!
   ! Copyright(C) 1996 Takuya OOURA (email: ooura@mmm.t.u-tokyo.ac.jp).      !
   ! You may use, copy, modify this code for any purpose and                 !
   ! without fee. You may distribute this ORIGINAL package.                  !
   !-------------------------------------------------------------------------!
   ! Modified by Ryusuke NUMATA 2008/06/27                                   !
   !  to fit F90 format                                                      !
   !-------------------------------------------------------------------------!

   ! these routines are declared as real, but can be promoted to
   ! double presicion using compiler option.
   ! this is so because constatns used are only double precision,
   ! and cannot be promoted to quad-precision.

   ! differences from GNU gfortran besj0 and besj1 are
   ! |err| < 1.e-15

!!$  elemental function erf(x)
!!$! A&S, p.299 7.1.28 |epsilon|<=3.e-7
!!$    implicit none
!!$    real, intent(in) :: x
!!$    real :: xerf
!!$    real, parameter, dimension(6) :: a = (/ &
!!$         0.0705230784, 0.0422820123, 0.0092705272, &
!!$         0.0001520143, 0.0002765672, 0.0000430638 /)
!!$
!!$    erf = 1.0 - 1.0/(1.0 + &
!!$         x*(a(1) + x*(a(2) + x*(a(3) + x*(a(4) + x*(a(5) + x*(a(6))))))))**16
!!$
!!$  end function erf

   elemental function erf_ext(x)

      ! error function in double precision
      real :: erf_ext
      real, intent(in) :: x
      integer :: k
      real :: w, t, y

      real, parameter :: a(0:64) = (/ &
           &  0.00000000005958930743, -0.00000000113739022964, &
           &  0.00000001466005199839, -0.00000016350354461960, &
           &  0.00000164610044809620, -0.00001492559551950604, &
           &  0.00012055331122299265, -0.00085483269811296660, &
           &  0.00522397762482322257, -0.02686617064507733420, &
           &  0.11283791670954881569, -0.37612638903183748117, &
           &  1.12837916709551257377, 0.00000000002372510631, &
           & -0.00000000045493253732, 0.00000000590362766598, &
           & -0.00000006642090827576, 0.00000067595634268133, &
           & -0.00000621188515924000, 0.00005103883009709690, &
           & -0.00037015410692956173, 0.00233307631218880978, &
           & -0.01254988477182192210, 0.05657061146827041994, &
           & -0.21379664776456006580, 0.84270079294971486929, &
           &  0.00000000000949905026, -0.00000000018310229805, &
           &  0.00000000239463074000, -0.00000002721444369609, &
           &  0.00000028045522331686, -0.00000261830022482897, &
           &  0.00002195455056768781, -0.00016358986921372656, &
           &  0.00107052153564110318, -0.00608284718113590151, &
           &  0.02986978465246258244, -0.13055593046562267625, &
           &  0.67493323603965504676, 0.00000000000382722073, &
           & -0.00000000007421598602, 0.00000000097930574080, &
           & -0.00000001126008898854, 0.00000011775134830784, &
           & -0.00000111992758382650, 0.00000962023443095201, &
           & -0.00007404402135070773, 0.00050689993654144881, &
           & -0.00307553051439272889, 0.01668977892553165586, &
           & -0.08548534594781312114, 0.56909076642393639985, &
           &  0.00000000000155296588, -0.00000000003032205868, &
           &  0.00000000040424830707, -0.00000000471135111493, &
           &  0.00000005011915876293, -0.00000048722516178974, &
           &  0.00000430683284629395, -0.00003445026145385764, &
           &  0.00024879276133931664, -0.00162940941748079288, &
           &  0.00988786373932350462, -0.05962426839442303805, &
           &  0.49766113250947636708/)

      real, parameter :: b(0:64) = (/ &
           & -0.00000000029734388465, 0.00000000269776334046, &
           & -0.00000000640788827665, -0.00000001667820132100, &
           & -0.00000021854388148686, 0.00000266246030457984, &
           &  0.00001612722157047886, -0.00025616361025506629, &
           &  0.00015380842432375365, 0.00815533022524927908, &
           & -0.01402283663896319337, -0.19746892495383021487, &
           &  0.71511720328842845913, -0.00000000001951073787, &
           & -0.00000000032302692214, 0.00000000522461866919, &
           &  0.00000000342940918551, -0.00000035772874310272, &
           &  0.00000019999935792654, 0.00002687044575042908, &
           & -0.00011843240273775776, -0.00080991728956032271, &
           &  0.00661062970502241174, 0.00909530922354827295, &
           & -0.20160072778491013140, 0.51169696718727644908, &
           &  0.00000000003147682272, -0.00000000048465972408, &
           &  0.00000000063675740242, 0.00000003377623323271, &
           & -0.00000015451139637086, -0.00000203340624738438, &
           &  0.00001947204525295057, 0.00002854147231653228, &
           & -0.00101565063152200272, 0.00271187003520095655, &
           &  0.02328095035422810727, -0.16725021123116877197, &
           &  0.32490054966649436974, 0.00000000002319363370, &
           & -0.00000000006303206648, -0.00000000264888267434, &
           &  0.00000002050708040581, 0.00000011371857327578, &
           & -0.00000211211337219663, 0.00000368797328322935, &
           &  0.00009823686253424796, -0.00065860243990455368, &
           & -0.00075285814895230877, 0.02585434424202960464, &
           & -0.11637092784486193258, 0.18267336775296612024, &
           & -0.00000000000367789363, 0.00000000020876046746, &
           & -0.00000000193319027226, -0.00000000435953392472, &
           &  0.00000018006992266137, -0.00000078441223763969, &
           & -0.00000675407647949153, 0.00008428418334440096, &
           & -0.00017604388937031815, -0.00239729611435071610, &
           &  0.02064129023876022970, -0.06905562880005864105, &
           &  0.09084526782065478489/)

      w = abs(x)
      if (w < 2.2) then
         t = w * w
         k = int(t)
         t = t - k
         k = k * 13
         y = ((((((((((((a(k) * t + a(k + 1)) * t + &
              & a(k + 2)) * t + a(k + 3)) * t + a(k + 4)) * t + &
              & a(k + 5)) * t + a(k + 6)) * t + a(k + 7)) * t + &
              & a(k + 8)) * t + a(k + 9)) * t + a(k + 10)) * t + &
              & a(k + 11)) * t + a(k + 12)) * w
      else if (w < 6.9) then
         k = int(w)
         t = w - k
         k = 13 * (k - 2)
         y = (((((((((((b(k) * t + b(k + 1)) * t + &
              & b(k + 2)) * t + b(k + 3)) * t + b(k + 4)) * t + &
              & b(k + 5)) * t + b(k + 6)) * t + b(k + 7)) * t + &
              & b(k + 8)) * t + b(k + 9)) * t + b(k + 10)) * t + &
              & b(k + 11)) * t + b(k + 12)
         y = y * y
         y = y * y
         y = y * y
         y = 1.-y * y
      else
         y = 1.
      end if
      if (x < 0.) y = -y
      erf_ext = y
   end function erf_ext

   !-------------------------------------------------------------------------!

# elif SPFUNC == _SPNAG_ /* if SPFUNC != _SPLOCAL_ */

   function j0(x)
      real :: j0
      real, intent(in) :: x
# if NAG_PREC == _NAGDBLE_
      real(kind=nag_kind), external :: s17aef ! bessel J0 double
# elif NAG_PREC == _NAGSNGL_
      real(kind=nag_kind), external :: s17aee ! bessel J0 single
# endif /* NAG_PREC */
      real(kind=nag_kind) :: xarg
      xarg = x
# if NAG_PREC == _NAGDBLE_
      j0 = s17aef(xarg, ifail)
# elif NAG_PREC == _NAGSNGL_
      j0 = s17aee(xarg, ifail)
# endif /* NAG_PREC */
   end function j0

   function j1(x)
      real :: j1
      real, intent(in) :: x
# if NAG_PREC == _NAGDBLE_
      real(kind=nag_kind), external :: s17aff ! bessel J1 double
# elif NAG_PREC == _NAGSNGL_
      real(kind=nag_kind), external :: s17afe ! bessel J1 single
# endif /* NAG_PREC */
      real(kind=nag_kind) :: xarg
      xarg = x
# if NAG_PREC == _NAGDBLE_
      j1 = s17aff(xarg, ifail)
# elif NAG_PREC == _NAGSNGL_
      j1 = s17afe(xarg, ifail)
# endif /* NAG_PREC */

      if (x == 0.) then
         j1 = .5
      else
         j1 = j1 / x
      end if
   end function j1

   function erf_ext(x)
      real :: erf_ext
      real, intent(in) :: x
# if NAG_PREC == _NAGDBLE_
      real(kind=nag_kind), external :: s15aef ! error function double
# elif NAG_PREC == _NAGSNGL_
      real(kind=nag_kind), external :: s15aee ! error function single
# endif /* NAG_PREC */
      real(kind=nag_kind) :: xarg
      xarg = x
# if NAG_PREC == _NAGDBLE_
      erf_ext = s15aef(xarg, ifail)
# elif NAG_PREC == _NAGSNGL_
      erf_ext = s15aee(xarg, ifail)
# endif /* NAG_PREC */
   end function erf_ext

# else /* if SPFUNC != _SPLOCAL_ && SPFUNC != _SPNAG_*/

# if (FCOMPILER == _G95_ || FCOMPILER == _GFORTRAN_ \
   ||FCOMPILER == _PATHSCALE_||FCOMPILER == _INTEL_)

# if FCOMPILER == _INTEL_
   function sj0(x)
      use ifport, only: besj0
# else
      elemental function sj0(x)
# endif
         real(kind=kind_rs), intent(in) :: x
         real(kind=kind_rs) :: sj0
         sj0 = besj0(x)
      end function sj0

# if FCOMPILER == _INTEL_
      function dj0(x)
         use ifport, only: dbesj0
# else
         elemental function dj0(x)
# endif
            real(kind=kind_rd), intent(in) :: x
            real(kind=kind_rd) :: dj0
            dj0 = dbesj0(x)
         end function dj0

# if FCOMPILER == _INTEL_
         function sj1(x)
            use ifport, only: besj1
# else
            elemental function sj1(x)
# endif
               real(kind=kind_rs), intent(in) :: x
               real(kind=kind_rs) :: sj1
               if (x == 0.0) then
                  sj1 = 0.5
               else
                  sj1 = besj1(x) / x
               end if
            end function sj1

# if FCOMPILER == _INTEL_
            function dj1(x)
               use ifport, only: dbesj1
# else
               elemental function dj1(x)
# endif
                  real(kind=kind_rd), intent(in) :: x
                  real(kind=kind_rd) :: dj1
                  if (x == 0.0) then
                     dj1 = 0.5
                  else
                     dj1 = dbesj1(x) / x
                  end if
               end function dj1

# if FCOMPILER == _G95_

               function erf_ext(x)
                  real, intent(in) :: x
                  real :: erf_ext
                  erf_ext = erf(x)
               end function erf_ext

# else /* if FCOMPILER != _G95_ */

# if FCOMPILER == _INTEL_
               function serf_ext(x)
# else
                  elemental function serf_ext(x)
# endif /* if FCOMPILER == _INTEL_ */
                     real(kind=kind_rs), intent(in) :: x
                     real(kind=kind_rs) :: serf_ext
                     serf_ext = erf(x)
                  end function serf_ext

# if FCOMPILER == _INTEL_
                  function derf_ext(x)
# else
                     elemental function derf_ext(x)
# endif
                        real(kind=kind_rd), intent(in) :: x
                        real(kind=kind_rd) :: derf_ext
                        derf_ext = derf(x)
                     end function derf_ext

# endif /* if FCOMPILER == _G95_ */

# elif FCOMPILER == _PGI_ /* if (FCOMPILER != one of _G95_, _GFORTRAN_, _INTEL_, _PATHSCALE_) */

                     elemental function j1(x)
                        real, intent(in) :: x
                        real :: j1
                        interface besj1
                           elemental function besj1(x)
                              real(kind=4), intent(in) :: x
                              real(kind=4) :: besj1
                           end function besj1
                           elemental function dbesj1(x)
                              real(kind=8), intent(in) :: x
                              real(kind=8) :: dbesj1
                           end function dbesj1
                        end interface
                        if (x == 0.0) then
                           j1 = 0.5
                        else
                           j1 = besj1(x) / x
                        end if
                     end function j1

# endif /* if FCOMPILER */

# endif /* if SPFUNC */

                     end module spfunc
