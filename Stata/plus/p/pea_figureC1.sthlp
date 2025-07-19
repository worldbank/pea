{smcl}
{* 10July2025}{...}
{hline}
help for {hi:pea figureC1}{right:July 2025}
{hline}

{title:Title}

{p 4 15}
{bf:pea figureC1} — Trends and nowcasts of poverty rates and GDP per-capita.

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
    {opt Year(varname numeric)} 
    [{opt year_fcast}
	{opt natpov_fcast}
	{opt gdp_fcast}
	{opt comparability_peb(varname string)}
	{opt yrange(string)} 
	{opt yrange2(string)} 
	{opt NOEQUALSPACING} 
	{opt scheme(string)}
	{opt palette(string)}	
	{opt using(string)} 	
	{opt excel(string)} 
	{opt save(string)}]{p_end} 
	
{title:Description}

{p 4 4 2}
{opt pea figureC1} generates core Figure 1, showing trends, now- and forecasts of the national poverty rate and GDP per capita (constant LCU.

{p 4 4 2}
Nowcasts..

Note that there are two options that are specific to this figure: yrange2(), which specifies the range of the second y-axis, and comparability_peb(), which denotes the variable that specifies comparable spells following PEB standards and formatting.
 
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
{opt Year(varname numeric)}:
 is the variable indicating the year for each observation.
    
{title:Additional options}
   
{p 4 4 2}
{opt year_fcast}: Only relevant for core Figure 1: To show now- and forecasts in the figure, insert the variable with forecast years here. 
The variable will specify for which year nowcast and forecast data is available. The variable needs to be created by the user.

{p 4 4 2}
{opt natpov_fcast}: Only relevant for core Figure 1: To show now- and forecasts in the figure, insert the variable with forecast national poverty here. 
The national poverty now- and forecast needs to be appended to the survey data.

{p 4 4 2}
{opt gdp_fcast}: Only relevant for core Figure 1: To show now- and forecasts in the figure, insert the variable with forecast GDP here.    
The GDP per-capita now- and forecast needs to be appended to the survey data.

{p 4 4 2}
{opt comparability_peb(varname numeric)}: Recommended: This variable denotes which survey rounds are comparable over time. 
The variable is taken from PEBs and follows its notation. Comparable spells are denoted by "Yes" and non-comparable by "No". Note that this is different from the comparability variable elsewhere specified.
Non-comparable survey rounds are not connected in figures. 

{p 4 4 2}  
{opt NOEQUALSPACING}: Optional. Adjusts year spacing on x-axis to be proportional to the distance between years. Default is that years are evenly spaced in the visualization.
     
{p 4 4 2}
{opt yrange}: Optional. Users can specify the range of the y-axis. The range must be entered in Stata figure format, such as "yrange(0(10)100)". In this figure, this specifies the LEFT y-axis (national poverty).
Default is that figures start at 0 and go up to the maximum value of the displayed data (next 10).
    
{p 4 4 2}
{opt yrange2}: Optional. For this figure, users can specify the range of the RIGHT y-axis (GDP per capita). The range must be entered in Stata figure format, such as "yrange(0(10)100)".
Default is that figures start at 0 and go up to the maximum value of the displayed data (next 10).

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
{bf:pea figureC1} [aw=weight_p], c(GNB) natw(natwelfare) natp(natline) year(year) comparability_peb(comparability_peb) yrange(20(20)80) yrange2(300000(50000)500000)

With forecasts:
pea core [aw=weight_p], c(GNB) natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline685) benchmark(SEN CIV GHA SLE) aggregate(groups) missing setting(GMD) spells(2018 2021) svy std(right) comparability_peb(comparability_peb) natpov_fcast(natpov_fcast) gdp_fcast(gdp_fcast) yrange(20(20)80) yrange2(300000(50000)500000)
