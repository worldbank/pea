{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea}{right:November 2024}
{hline}

{title:Title}

    {bf:[PEA] pea} - Package for poverty indicators developed by World Bank Staff.

{p 4 15}
{it:[Suggestion: Read}
{browse "https://openknowledge.worldbank.org/handle/10986/37728":Guidelines for PEA indicators}
{it:first.]}

{title:Description}

{p 4 4 2}
Stata ado program to standardize data annex and additional analysis using the Global Monitoring Database (GMD) or country-specific database.	
The {opt  pea} suite of commands are made for poverty indicators. To become familiar with the sae suite of commands see:	
	
	1. Program to produce core tables:
{col 7}{...}
     {bf:{help pea core:[PEA] pea core}} 
	2. Program to produce extended set of tables
{col 7}{...}
     {bf:{help pea tables:[PEA] pea tables}} 
	3. Program to produce figures:
{col 7}{...}
     {bf:{help pea figures:[PEA] pea figures}} 
	
	   
{p 4 4 2}
To perform update data sources see:

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

