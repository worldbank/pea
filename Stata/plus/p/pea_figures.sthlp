{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea figures}{right:January 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea figures} — full set of figures to support the narratives on key topics such as growth, poverty, and inequality.

{title:Syntax}

{p 4 15}
{opt pea figures} 
	[{it:if}] 
	[{it:in}] 
	[{it:aw pw fw}]
{opt ,} 
[{opt natwelfare(varname numeric)}
 {opt natpovlines(varlist numeric)} 
 {opt pppwelfare(varname numeric)} 
 {opt ppppovlines(varlist numeric)}
 {opt year(varname numeric)} 
 {opt setting(string)} 
 {opt excel(string)} 
 {opt save(string)} 
 {opt byind(varlist numeric)}
 {opt age(varname numeric)}
 {opt male(varname numeric)} 
 {opt hhhead(varname numeric)} 
 {opt edu(varname numeric)}
 {opt urban(varname numeric)} 
 {opt married(varname numeric)} 
 {opt school(varname numeric)}
 {opt services(varlist numeric)} 
 {opt assets(varlist numeric)}
 {opt hhsize(varname numeric)}
 {opt hhid(string)}
 {opt pid(string)}
 {opt industrycat4(varname numeric)}
 {opt lstatus(varname numeric)} 
 {opt empstat(varname numeric)} 
 {opt oneline(varname numeric)} 
 {opt onewelfare(varname numeric)} 
 {opt missing} 
 {opt country(string)} 
 {opt within(integer)} 
 {opt combine}
 {opt nonotes} 
 {opt comparability(varname numeric)}
 {opt benchmark(string)} 
 {opt spells(string)} 
 {opt equalspacing} 
 {opt scheme(string)}
 {opt palette(string)} 
 {opt welfaretype(string)}]{p_end}

{p 4 4 2}
The following are NON-mandatory options and are only used if setting(GMD) is not specified:
{bf:hhhead, edu, married, school, services, assets, hhsize, hhid, pid, industrycat4, lstatus, and empstat}.

{title:Description}

{p 4 4 2}
{opt pea figures} generates a series of figures that are produced using the pea figures command in Stata for the convenience of the user. 
Figures span a broad range of topics, including a comparison of poverty rates and GDP per capita with other countries, changes in poverty and inequality over time, population composition by income decile, profiles, or exposure and risk from climate-related hazards.

{p 4 4 2}
The program supports a wide range of inputs, including national and PPP welfare and poverty lines, 
demographic variables, and survey metadata. Users can output results directly to an Excel file.

{p 4 4 2}
The program performs several data quality checks, including missing observations and weight 
verifications. It also ensures that the inputs meet the requirements for each figure type. 

{p 4 4 2}
Each figure is generated sequentially and saved to the specified Excel file or a temporary file.

{p 4 4 2}
The following figures are available within the {opt pea figures} command, each serving a distinct purpose. For more detailed explanations of their contents and usage, see below:{p_end}

{p 4 7}{opt Figure 1}: Poverty rates by year lines.{p_end}
{p 4 7}{bf:{help pea figure1:[PEA] pea figure1}} 

{p 4 7}{opt Figure 2}: Poverty and GDP per capita scatter.{p_end}
{p 4 7}{bf:{help pea figure2:[PEA] pea figure2}} 

{p 6 7}
NOTE: only works for the international poverty lines, to be exact 2.15, 3.65, 6.85, 2017 PPP

{p 4 7}{opt Figure 3}: Growth Incidence Curve.{p_end}
{p 4 7}{bf:{help pea figure3:[PEA] pea figure3}} 

{p 4 7}{opt Figure 4}: Decomposition of poverty changes: growth and redistribution: Datt-Ravallion and Shorrocks-Kolenikov.{p_end}
{p 4 7}{bf:{help pea figure4:[PEA] pea figure4}} 

{p 4 7}{opt Figure 5}: Decomposition of poverty changes: growth and redistribution: Huppi-Ravallion.{p_end}
{p 4 7}{bf:{help pea figure5:[PEA] pea figure5}} 

{p 4 7}{opt Figure 6}: GDP per capita GDP - Poverty elasticity.{p_end}
{p 4 7}{bf:{help pea figure6:[PEA] pea figure6}}

{p 4 7}{opt Figure 7}: Welfare Figure with poverty line breakdowns.{p_end}
{p 4 7}{bf:{help pea figure7:[PEA] pea figure7}} 

{p 4 7}{opt Figure 9a}: Inequality by year lines.{p_end}
{p 4 7}{bf:{help pea figure9a:[PEA] pea figure9a}} 

{p 4 7}{opt Figure 9b}: GINI and GDP per capita scatter.{p_end}
{p 4 7}{bf:{help pea figure9b:[PEA] pea figure9b}} 

{p 4 7}{opt Figure 10a}: Prosperity gap by year lines.{p_end}
{p 4 7}{bf:{help pea figure10a:[PEA] pea figure10a}} 

{p 4 7}{opt Figure 10b}: Prosperity gap scatter (line-up).{p_end}
{p 4 7}{bf:{help pea figure10b:[PEA] pea figure10b}} 

{p 4 7}{opt Figure 10c}: PG (survey) and GDP per capita scatter.{p_end}
{p 4 7}{bf:{help pea figure10c:[PEA] pea figure10c}} 

{p 4 7}{opt Figure 12}: Decomposition of growth in prosperity gap.{p_end}
{p 4 7}{bf:{help pea figure12:[PEA] pea figure12}}

{p 4 7}{opt Figure 13}: Distribution of welfare by deciles{p_end}
{p 4 7}{bf:{help pea figure13:[PEA] pea figure13}} 

{p 4 7}{opt Figure 14}: Multidimensional poverty: Multidimensional Poverty Measure (World Bank).{p_end}
{p 4 7}{bf:{help pea figure14:[PEA] pea figure14}} 

{p 4 7}{opt Figure 15}: Climate risk and vulnerability.{p_end}
{p 4 7}{bf:{help pea figure15:[PEA] pea figure15}} 

{title:Options}

Main options:

{p 4 4 2}
{opt Country(string)}: 3-letter country code for the analysis.

{p 4 4 2}
{opt NATWelfare(varname numeric)}: specifies the variable for national welfare measures.

{p 4 4 2}
{opt NATPovlines(varlist numeric)}: specifies a list of national poverty lines to use.

{p 4 4 2}
{opt PPPWelfare(varname numeric)}: specifies the variable for purchasing power parity (PPP) adjusted welfare.

{p 4 4 2}
{opt PPPPovlines(varlist numeric)}: specifies a list of PPP-adjusted poverty lines.

{p 4 4 2}
{opt Year(varname numeric)}: specifies the year variable for the analysis.

{p 4 4 2}
{opt setting(string)}: Optional. If GMD option is specified, harmonized variables are created, and additional options (hhhead(), edu(), married(), school(), services(), assets(), hhsize(), hhid(), pid(), industrycat4(), lstatus(), and empstat()) do not need to be specified.

{p 4 4 2}
{opt excel(string)}: specifies the file path for exporting results to Excel.

{p 4 4 2}
{opt save(string)}: specifies the file path for saving results.

{p 4 4 2}
{opt BYInd(varlist numeric)}: specifies the variables by which to break down the analysis (e.g., urban/rural, subnational).

{p 4 4 2}
{opt ONELine(varname numeric)}: specifies the one-line poverty line variable.

{p 4 4 2}
{opt ONEWelfare(varname numeric)}: specifies the one-line welfare variable.

{p 4 4 2}
{opt MISSING}: Optional. Includes missing data in the analysis.

{p 4 4 2}
{opt LATEST}: includes only the most recent available data.

{p 4 4 2}
{opt BENCHmark(string)}: specifies a list of benchmark countries (e.g., ALB HRV XKX).

{p 4 4 2}
{opt spells(string)}: specifies the periods or time spells for longitudinal analysis (e.g., 2015 2016; 2016 2017).

{p 4 4 2}
{opt within(integer)}: Optional. Specifies the number of years before and after the pea survey year, to define which surveys from other countries should be used (e.g. in scatter plots on inequality). 
Default is 3, and value should be less than 10.

{p 4 4 2}
{opt combine}: Optional. When specified, figures with multiple panels are combined to one figure with only one legend.

{p 4 4 2}
{opt nonotes}: Optional. Suppresses that standard notes are added beneath figures. 

{p 4 4 2}
{opt comparability(varname numeric)}: Required. This variable denotes which survey rounds are comparable over time. 
Non-comparable survey rounds are not connected in figures. Example:	comparability(comparability).

{p 4 4 2}
{opt equalspacing}: Optional. When specified, figures display constant gaps between years, regardless of how far away years are. 
This can be useful if gaps between survey-years are large.

{p 4 4 2}
{opt scheme(string)}: Optional. Sets the scheme, specifying the overall look of the figures. 
Default is “white_tableau”.

{p 4 4 2}
{opt palette(string)}: Optional. Sets the color palette for figures. Default is “tab20”. 
See Annex 1: Example. Either string (e.g. vividis) or list of colors.

{p 4 4 2}
{opt welfaretype(string)}: Optional. Can be used to specify whether the survey uses income or consumption to calculate welfare. 
Figures showing scatters of inequality display different symbols for countries with consumption or income aggregates. Either CONS or INC.


Additional options if setting(GMD) is not specified:

{p 4 4 2}
{opt age(varname numeric)}: specifies the age variable for the analysis.
Default under setting(GMD): age

{p 4 4 2}
{opt male(varname numeric)}: specifies the gender variable (e.g., male/female).
Default under setting(GMD): male

{p 4 4 2}
{opt hhhead(varname numeric)}: specifies the household head status variable.
Default under setting(GMD): head

{p 4 4 2}
{opt edu(varname numeric)}: specifies the education level variable.
Default under setting(GMD): educat4    

{p 4 4 2}
{opt urban(varname numeric)}: specifies the urban/rural classification variable.
Default under setting(GMD): urban

{p 4 4 2}
{opt married(varname numeric)}: specifies the marital status variable.
Default under setting(GMD): married

{p 4 4 2}
{opt school(varname numeric)}: specifies the schooling variable.
Default under setting(GMD): school

{p 4 4 2}
{opt services(varlist numeric)}: specifies a list of household service variables (e.g., water access, sanitation).
Default under setting(GMD): imp_wat_rec imp_san_rec electricity

{p 4 4 2}
{opt assets(varlist numeric)}: specifies a list of household asset variables (e.g., TV, car, cellphone).
Default under setting(GMD): tv car cellphone computer fridge

{p 4 4 2}
{opt hhsize(varname numeric)}: specifies the household size variable.
Default under setting(GMD): hsize

{p 4 4 2}
{opt hhid(string)}: specifies the household ID variable.
Default under setting(GMD): hhid

{p 4 4 2}
{opt pid(string)}: specifies the individual ID variable.
Default under setting(GMD): pid

{p 4 4 2}
{opt industrycat4(varname numeric)}: specifies the industry category variable.
Default under setting(GMD): industrycat4

{p 4 4 2}
{opt lstatus(varname numeric)}: specifies the labor status variable (e.g., employed, unemployed).
Default under setting(GMD): nowork

{p 4 4 2}
{opt empstat(varname numeric)}: specifies the employment status variable.
Default under setting(GMD): empstat

{title:Examples}

{p 4 4 2}
{bf:pea figures}[aw=weight_p], c(IDN) natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline685) benchmark(MYS VNM THA) missing setting(GMD) 
spells(2000 2007; 2007 2008; 2016 2022) comparability(comparability) welfaretype(CONS)
