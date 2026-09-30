*==============================================================
* PEA -- PEER COMPARISON ONLY
* Author: Daylan Salmeron Gomez
*Email: dsalmerongomez@worldbank.org
*==============================================================
*
* Produces the income-group and regional comparator columns of
* Table C.1 WITHOUT needing the country's own survey data.
*
* WHY THIS EXISTS
*   The pea commands are built around the country's microdata
*   being loaded. Teams starting a PEA before their survey is
*   harmonized in the GMD cannot run them at all, even though
*   the comparator figures come entirely from data that ships
*   with the package.
*
* HOW IT WORKS
*   It loads a small placeholder dataset so the command will
*   run, then reads the peer numbers from the package's cached
*   files. The peer columns are REAL. The country column is
*   NOT -- it is computed from the placeholder.
*
* WHAT YOU MUST DO
*   1. Set COUNTRY below to a real code in your region. The code
*      determines which income group and region the peers are
*      drawn from, so it must be the country you are writing
*      about.
*   2. Set REFYEAR to your survey's reference year. Peers are
*      selected within +/- 3 years of it, so this changes which
*      countries appear.
*   3. DELETE THE FIRST DATA COLUMN from the output before
*      sharing the workbook. It contains invented numbers under
*      a real country code.
*
* This is a stopgap. A proper peersonly option is on the
* roadmap; raise it with the PEA package maintainers.
*==============================================================

version 18
clear all
set more off


*==============================================================
* CONFIGURE
*==============================================================

* Country whose peer group you want. Real ISO3 code.
local COUNTRY  "COD"

* Reference year of your (future) survey. Drives peer selection.
local REFYEAR  2024

* PPP round and matching poverty lines.
*   2017 -> 2.15 / 3.65 / 6.85
*   2021 -> 3.00 / 4.20 / 8.30
local PPPYEAR  2017
local LINE1    2.15
local LINE2    3.65
local LINE3    6.85

* Where to write. The folder must exist.
local OUTFILE  "C:/Users/wb570371/Downloads/pea_test/peers_`COUNTRY'_`REFYEAR'.xlsx"

* Optional: specific comparator countries instead of the whole
* income group. Leave empty to use income group and region.
local BENCHMARK ""


*==============================================================
* CHECKS
*==============================================================
if length("`COUNTRY'") != 3 {
    di as error "COUNTRY must be a 3-letter ISO3 code. Got: `COUNTRY'"
    exit 198
}
if `PPPYEAR' == 2017 & `LINE1' != 2.15 {
    di as error "PPPYEAR is 2017 but the lines are not the 2017 lines."
    di as error "The package will reject this with r(200), correctly."
    exit 198
}
if `PPPYEAR' == 2021 & `LINE1' != 3.00 {
    di as error "PPPYEAR is 2021 but the lines are not the 2021 lines."
    exit 198
}


*==============================================================
* PLACEHOLDER DATA
*    Every value here is invented. Its only job is to satisfy
*    the command's required variables so the peer computation
*    can run. Nothing in the country column is meaningful.
*==============================================================
clear
set obs 100

gen year            = `REFYEAR'
gen double welfare  = 100
gen double welfppp  = 5
gen double natline  = 120
gen double pline215 = `LINE1'
gen double pline365 = `LINE2'
gen double pline685 = `LINE3'
gen weight_p        = 1
gen byte urban        = mod(_n,2)
gen byte nowork       = mod(_n,3)==0
gen byte empstat      = mod(_n,4)+1
gen byte industrycat4 = mod(_n,4)+1
gen byte educat4      = mod(_n,4)+1
gen int  age          = 20 + mod(_n,50)
gen byte male         = mod(_n,2)
gen long hhid         = ceil(_n/4)
gen long pid          = _n
gen byte hsize        = 4

label var welfare  "PLACEHOLDER -- not real data"
label var welfppp  "PLACEHOLDER -- not real data"


*==============================================================
* RUN
*==============================================================
cap erase "`OUTFILE'"
putexcel set "`OUTFILE'", replace sheet("Contents")
putexcel A1 = "PEER COMPARISON ONLY -- see the warning on this sheet"
putexcel save
putexcel clear

local opts c(`COUNTRY') natw(welfare) natp(natline) pppw(welfppp)
local opts `opts' pppp(pline215 pline365 pline685) year(year)
local opts `opts' onew(welfppp) onel(pline215) pppy(`PPPYEAR')
local opts `opts' lstatus(nowork) empstat(empstat)
local opts `opts' industrycat4(industrycat4) age(age) male(male)

if "`BENCHMARK'" == "" local agg aggregate(groups)
else                   local agg benchmark(`BENCHMARK') aggregate(benchmark)

di as text _newline "Running peer comparison for `COUNTRY', reference year `REFYEAR'..."

cap noi pea tableC1 [aw=weight_p], `opts' `agg' excel("`OUTFILE'")
local rc = _rc

if `rc' != 0 {
    di as error _newline "Failed with r(`rc')."
    di as error "If it names a missing variable, add it to the"
    di as error "placeholder block above and rerun."
    exit `rc'
}


*==============================================================
* WARNING INTO THE WORKBOOK
*    A console message disappears. The file gets emailed on.
*    The warning has to live in the file.
*==============================================================
local warn1 "WARNING: THE COUNTRY COLUMN IN THIS FILE IS NOT REAL DATA."
local warn2 "This workbook was produced for PEER COMPARISON ONLY. The country code `COUNTRY' is real, but no survey data for `COUNTRY' was used. Its column was computed from placeholder values and must be deleted before this file is shared or cited."
local warn3 "The comparator columns (income group, region, benchmark countries) ARE real, drawn from the PEA package data for reference year `REFYEAR'."

foreach sh in Contents TableC1 {
    cap putexcel set "`OUTFILE'", modify sheet("`sh'")
    if _rc continue
    cap putexcel A1 = "`warn1'", font("Calibri", 12, "FF0000") bold
    cap putexcel A2 = "`warn2'", font("Calibri", 10, "FF0000")
    cap putexcel A3 = "`warn3'", font("Calibri", 10, "000000")
    cap putexcel save
    cap putexcel clear
}


*==============================================================
* CONSOLE NOTICE
*==============================================================
local bar : di _dup(70) "*"

di as error _newline "`bar'"
di as error "  PEER COMPARISON ONLY"
di as error "`bar'"
di as text  ""
di as text  "  Output: " as result "`OUTFILE'"
di as text  ""
di as error "  The `COUNTRY' column is NOT real data."
di as text  "  It was computed from placeholder values so the command"
di as text  "  would run. Delete that column before sharing the file."
di as text  ""
di as text  "  The comparator columns are real: peers were selected"
di as text  "  within +/- 3 years of `REFYEAR' from `COUNTRY''s income"
di as text  "  group and region."
di as error "`bar'"