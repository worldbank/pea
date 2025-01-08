{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea}{right:January 2025}
{hline}

{title:Title}

{bf:[PEA] pea} - Stata programs to standardize data annex and additional analysis using the Global Monitoring Database (GMD) or country-specific database.

{p 4 15}
{it:[Suggestion: Read}
{browse "https://openknowledge.worldbank.org/handle/10986/37728": Guidelines for PEA indicators}
{it:first.]}

{title:Description}

{p 4 4 2}
Stata codes that produce a comprehensive set of outputs to analyze trends in poverty, shared prosperity and inequality, as well as their drivers and profiles. New Stata commands generate the tables and figures for the standardized data annex (pea core  ), a full set of tables (pea tables) and figures (pea figures) that can be used for the production of core diagnostics in PEAs. Outputs are Excel files with sheets of formatted tables and figures. 
To become familiar with the {bf:[PEA]} suite of commands see:	
	
	1. Core: core tables and figures for the standardized data annex.
{col 7}{...}
     {bf:{help pea core:[PEA] pea core}} 
	2. Tables: full set of tables for the main body of the PEA, either with the GMD or country-specific data.
{col 7}{...}
     {bf:{help pea tables:[PEA] pea tables}} 
	3. Figures: full set of figures to support the narratives on key topics such as growth, poverty, and inequality.
{col 7}{...}
     {bf:{help pea figures:[PEA] pea figures}} 
	
	   
{p 4 4 2}
To perform update data sources:

{col 7}{...}
{hline 70}
{col 7}{bf:{help pea dataupdate: pea dataupdate}}{...}
{col 30}updates data for multiple countries
{...}
{...}
{col 7}{...}
{hline 70}
{p 6 6 2}


{p 4 4 2}
To change figures setup:

{col 7}{...}
{hline 70}
{col 7}{bf:{help pea figure_setup: pea figure_setup}}{...}
{col 30}updates settings for all figures
{...}
{...}
{col 7}{...}
{hline 70}
{p 6 6 2}

{marker Note}{...}
{title:Note on data preparation}

{p 4 4 2}
- Table and figure outputs are good if the input data is prepared.

{p 4 4 2}
- Utility the GMD database for the historical/recent data points. If it is too new, work with the regional/global teams to bring it into the GMD.

{p 4 4 2}
- If not using the GMD, make sure you replicate the international poverty rates with your data. Work with the global team (D4G) on the correct CPI/ICP values for the (new) surveys.

{p 4 4 2}
- Survey weights are important!

{p 4 4 2}
- As PE, you are the best resources when it comes to national welfare and national poverty lines.

{title:Example}

The following code produces the main tables, and the standardized data annex for Guinea-Bissau:

{p 4 4 2}
// Datalibweb setup

{p 4 4 2}
datalibweb, country(GNB) year(2018 2021) type(gmd) mod(all) clear

{p 4 4 2}
// Preparation of additional variables
	
	gen welfppp = welfare/cpi2017/icp2017/365
	
	gen pline215 = 2.15
	
	gen pline365 = 3.65
	
	gen pline685 = 6.85
	
	gen natline = 298083.5 if year == 2021
	
	replace natline = 271071.8 if year == 2018
	
	la var pline215 "Poverty line: $2.15 per day (2017 PPP)"
	
	la var pline365 "Poverty line: $3.65 per day (2017 PPP)"
	
	la var pline685 "Poverty line: $6.85 per day (2017 PPP)"
	
	la var natline "Poverty line: 298,083.5 per year (2017 LCU)"
	
	split subnatid, parse("-") gen(tmp)
	
	replace tmp2 = ustrlower( ustrregexra( ustrnormalize( tmp2, "nfd" ) , "\p{Mark}", "" ) )
	
	replace tmp2 = " bolama/bijagos" if tmp2 == " bolama_bijagos"
	
	replace tmp2 = proper(tmp2)
	
	encode tmp2, gen(subnatvar)

{p 4 4 2}
// Main tables code:

{p 4 4 2}
pea tables [aw=weight_p], c(GNB) natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline685) benchmark(SEN GMB) missing setting(GMD) spells(2018 2021)

{p 4 4 2}
// Appendix tables code:

{p 4 4 2}
pea core [aw=weight_p], c(GNB) natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline685) benchmark(SEN GMB) missing setting(GMD) spells(2018 2021)

{p 4 4 2}
// Appendix tables code without setting(GMD)

{p 4 4 2}
pea core [aw=weight_p], c(GNB) natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) age(age) male(male) hhhead(head) edu(educat4) urban(urban) married(married) school(school) services(imp_wat_rec imp_san_rec electricity) assets(tv car cellphone computer fridge) hhsize(hsize) hhid(hhid) pid(pid) industrycat4(industrycat4) lstatus(nowork) empstat(empstat) benchmark(SEN GMB LIB) onew(welfppp) onel(pline215) missing spells(2018 2021)

{p 4 4 2}
// Figures code:

{p 4 4 2}
pea figures [aw=weight_p], c(GNB) year(year natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) onew(welfppp) oneline(pline215) byind(urban) benchmark(CIV GHA GMB SEN AGA) spells(2010 2018; 2018 2021) setting(GMD) urban(urban)	within(3) comparability(comparability) combine welfaretype(CONS) nonotes palette(viridis)

{p 4 4 2}
// Defining own color palette

{p 4 4 2}
local custom_palette = "#337ab7 #5cb85c #5bc0de #f0ad4e #d9534f #e6e6e6 #286090 #449d44 #31b0d5 #ec971f #c9302c"
pea figure2 [aw=weight_p], c(GNB) year(year) onew(welfppp) onel(pline215) benchmark(CIV GHA GMB SEN) palette(`custom_palette')


{marker references}{...}
{title:References}

{p 4 4 2}- Azevedo, Joao Pedro and Viviane Sanfelice (2012) "The rise of the middle class in Latin America". World Bank (mimeo). {p_end}
{p 4 4 2}- Ferreira, Francisco H.G.; Messina, Julian; Rigolini, Jamele; López-Calva, Luis-Felipe; Lugo, Maria Ana; Vakis, Renos. (2013) Economic Mobility and the Rise of the Latin American Middle Class. Washington, DC: World Bank. 
{browse "https://openknowledge.worldbank.org/handle/10986/11858" : (link to publication)}{p_end}
{p 4 4 2}- Datt, G.; Ravallion, M. (1992) Growth and Redistribution Components of Changes in Poverty Measures: A Decomposition with Applications to Brazil and India in the 1980s. Journal of Development Economics, 38: 275-296.{p_end}
{p 4 4 2}- Shorrocks, A. F. (2012) Decomposition procedures for distributional analysis: a unified framework based on the Shapley value. Journal of Economic Inequality.{p_end}
{p 4 4 2}- Shorrocks, A.; Kolenikov, S. (2003) A Decomposition Analysis of Regional Poverty in Russia, Discussion Paper No. 2003/74 United Nations University.{p_end}
{p 4 4 2}- World Bank (2011) On The Edge Of Uncertainty: Poverty Reduction in Latin America and the Caribbean during the Great Recession and Beyond. {opt LAC Poverty and Labor Brief}. World Bank: Washington DC.
{browse "http://siteresources.worldbank.org/INTLAC/Resources/LAC_poverty_report.pdf" : (link to publication)}{p_end}

{title:Authors}	

{p 5} Minh Cong Nguyen, 		mnguyen3@worldbank.org{p_end}
{p 5} Sandra Segovia Juarez, 	ssegoviajuarez@worldbank.org{p_end}
{p 5} Henry Stemmler, 			hstemmler@worldbank.org{p_end}

{title:Thanks for citing {opt  sae} as follows}

{p 4 4 2}{opt  pea} is a user-written program that is freely distributed to the research community. {p_end}

{p 4 4 2}Please use the following citation:{p_end}


{title:Acknowledgements}

{p 4 4 2}We would like to thank all the users for their comments during the initial development of the codes. 
All errors and ommissions are exclusively our responsibility.{p_end}
	
	
{title:Also see}

{p 2 4 2} help for {help gidecomposition}; {help apoverty}; {help ainequal};  {help wbopendata}; {help adecomp}; {help mpovline}; {help skdecomp} (if installed){p_end} 

