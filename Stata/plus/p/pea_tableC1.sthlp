{smcl}
{* 10July2025}{...}
{hline}
help for {hi:pea tableC1}{right:July 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea tableC1} — Key Poverty, Shared Prosperity and Labor Market Indicators.

{title:Syntax}

{p 4 15}
{opt pea tableC1}
	[{it:weight}] 
	[{opt if} {it:exp}] 
	[{opt in} {it:exp}] 
	{opt ,}  
	{opt Country(string)} 
    {opt NATWelfare(varname numeric)} 
	{opt NATPovlines(varlist numeric)} 
    {opt PPPWelfare(varname numeric)} 
	{opt PPPPovlines(varlist numeric)} 
    {opt Year(varname numeric)} 
	{opt lstatus(varname numeric)}
	{opt empstat(varname numeric)}
	{opt industrycat4(varname numeric)}
	{opt age(varname numeric)}
	{opt male(varname numeric)}	
    [{opt aggregate(string)} 
	{opt vulnerability(string)}
	{opt PPPyear(integer)}
	{opt using(string)} 	
	{opt excel(string)} 
	{opt save(string)}]{p_end} 
	
{title:Description}

{p 4 4 2}
{opt pea tableC1} generates core poverty, shared prosperity, labor market and vulnerability indicators based on specified national and international poverty lines and welfare indicators.

{p 4 4 2}
All indicators are produced for the PEA country and one of the following three: A set of peer countries, averages of the PEA country's region and income groupo, or averages of the peer countries (see option aggregat() below). 
Peers, regional and income group countries are included if a survey exists within three years of the last survey year of the PEA country. 
Indicators based on national poverty lines are not shown for comparators.
 
{title:Required options}

{p 4 4 2} 
{opt Country(string)}:
 specifies the country code or name for the analysis.
    
{p 4 4 2} 
{opt NATWelfare(varname numeric)}:
 is the variable containing welfare values for national analysis.

{p 4 4 2} 
{opt NATPovlines(varlist numeric)}:
lists the national poverty lines used in the analysis.
    
{p 4 4 2} 
{opt PPPWelfare(varname numeric)}:
 is the welfare variable adjusted for purchasing power parity (PPP).
    
{p 4 4 2} 
{opt PPPPovlines(varlist numeric)}:
 lists the PPP-adjusted poverty lines.
    
{p 4 4 2} 
{opt Year(varname numeric)}:
 is the variable indicating the year for each observation.
    
{p 4 4 2} 
{opt ONELine(varname numeric)}:
 is the poverty line variable used to calculate vulnerability to poverty.

{p 4 4 2} 
{opt ONEWelfare(varname numeric)}:
 is the welfare variable associated with the {opt ONELine} poverty line (for vulnerability to poverty).

{p 4 4 2}
{opt age(varname numeric)}: specifies the age variable for the analysis.
Default under setting(GMD): age

{p 4 4 2}
{opt male(varname numeric)}: specifies the gender variable (e.g., male/female).
Default under setting(GMD): male

{p 4 4 2}
{opt lstatus(varname numeric)}: specifies the labor status variable (e.g., employed, unemployed). Please note that the input variable should have 'not working' (i.e. unemployed or out of labor force) as the value = 1, and employed as a different value. 
Default under setting(GMD): nowork

{p 4 4 2}
{opt empstat(varname numeric)}: specifies the employment status variable.
Default under setting(GMD): empstat
 
{p 4 4 2}
{opt industrycat4(varname numeric)}: specifies the industry category variable.
Default under setting(GMD): industrycat4

{title:Additional options}
     
{p 4 4 2}
{opt PPPyear(integer)}: specifies which year PPPs are based on (e.g. 2017 or 2011).
Default is 2017.

{p 4 4 2}
{opt aggregate(string)}: specifies the way comparator countries or aggregates are displayed.
	Available options are: 
	
	- Default: If aggregate() is not specified, peer countries will be shown individually.
	- aggregate({bf: groups}): Will display aggregate values for countries within the same region or income group as PEA countries (using population weights). 
		Region and income group countries are included if a survey within 3 years of last survey year of the PEA country is available. 
		Note: Regional and income group poverty rates deviate from official World Bank published rates, as no line-up values are used.
	- aggregate({bf: benchmark}): Will display aggregate values for peer countries specified in option {bf: benchmark(string)}). 
		Peer countries are included if a survey within 3 years of last survey year of the PEA country is available.
  
{p 4 4 2}
{opt vulnerability(string)}: specifies the value by which the main poverty line (as passed in option oneline()) is multiplied to define vulnerability to poverty.
Vulnerability to poverty is defined as being between the main and the multiple of the poverty line. Default is vulnerability(1.5).

{p 4 4 2} 
{opt using(string)}:
 specifies the dataset to use; the dataset will be loaded if provided.

{p 4 4 2} 
{opt excel(string)}:
 specifies an Excel file for saving the results. If this option is not specified, a temporary file will be used.

{p 4 4 2} 
{opt save(string)}:
 specifies a file path to save the generated table in Stata format. 

{title:Examples}

{p 4 4 2}     
{bf:pea tableC1} [aw=weight_p], c(PHL) natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) onew(welfppp) onel(pline215) ppp(2017) benchmark(VNM IDN THA) lstatus(nowork) empstat(empstat) industrycat4(industrycat4) age(age) male(male)

{p 4 4 2} 
{bf:pea tableC1} [aw=weight_p], c(PHL) natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) onew(welfppp) onel(pline215) ppp(2017) lstatus(nowork) empstat(empstat) industrycat4(industrycat4) age(age) male(male) aggregate(groups)

{p 4 4 2} 
{bf:pea tableC1} [aw=weight_p], c(PHL) natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) onew(welfppp) onel(pline215) ppp(2017) benchmark(VNM IDN THA) lstatus(nowork) empstat(empstat) industrycat4(industrycat4) age(age) male(male) aggregate(benchmark)

{p 4 4 2} 
{bf:pea tableC1} [aw=weight_p], c(GNB) natw(welfarenom) natp(natline) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) onew(welfppp) onel(pline215) ppp(2021) lstatus(nowork) empstat(empstat) industrycat4(industrycat4) age(age) male(male) aggregate(groups)
