{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea tables}{right:November 2024}
{hline}

{title:Title}

{p 4 15}
{opt pea_figures} — Generate poverty and equity analytics figures

{hline}

{title:Syntax}

{p 8 12 2}
{opt pea figures} 
[{it:if}] 
[{it:in}] 
[{it:weight}] 
{opt ,} 
[{opt natwelfare(varname)}
 {opt natpovlines(varlist)} 
 {opt pppwelfare(varname)} 
 {opt ppppovlines(varlist)}
 {opt year(varname)} 
 {opt setting(string)} 
 {opt excel(string)} 
 {opt save(string)} 
 {opt byind(varlist)}
 {opt age(varname)}
 {opt male(varname)} 
 {opt hhhead(varname)} 
 {opt edu(varname)}
 {opt urban(varname)} 
 {opt married(varname)} 
 {opt school(varname)}
 {opt services(varlist)} 
 {opt assets(varlist)}
 {opt hhsize(varname)}
 {opt hhid(string)}
 {opt pid(string)}
 {opt industrycat4(varname)}
 {opt lstatus(varname)} 
 {opt empstat(varname)} 
 {opt oneline(varname)} 
 {opt onewelfare(varname)} 
 {opt missing} 
 {opt country(string)} 
 {opt within(integer)} 
 {opt combine}
 {opt nonotes} 
 {opt comparability(varname)}
 {opt benchmark(string)} 
 {opt spells(string)} 
 {opt equalspacing} 
 {opt scheme(string)}
 {opt palette(string)} 
 {opt welfaretype(string)}]{p_end}

{title:Description}

{pstd}
{opt pea figures} generates a series of figures and tables for Poverty and Equity Analytics (PEA), 
based on the provided welfare data and survey information. Figures include poverty trends, 
distributional analysis, and other equity-related measures.

{pstd}
The program supports a wide range of inputs, including national and PPP welfare and poverty lines, 
demographic variables, and survey metadata. Users can output results directly to an Excel file.


{p 4 7}{opt Figure 1}: Poverty rates by year lines.{p_end}
//todo: add comparability, add the combine graph options
{p 4 7}{bf:{help pea_figure1:[PEA] pea figure1}} 

{p 4 7}{opt Figure 2}: Poverty and GDP per capita scatter.{p_end}
//Note on helpfile: only work for the international poverty lines, to be exact 2.15, 3.65, 6.85, 2017 PPP
{p 4 7}{bf:{help pea_figure2:[PEA] pea figure2}} 

{p 4 7}{opt Figure 3}: Growth Incidence Curve.{p_end}
{p 4 7}{bf:{help pea_figure3:[PEA] pea figure3}} 

{p 4 7}{opt Figure 4}: Decomposition of poverty changes: growth and redistribution: Datt-Ravallion and Shorrocks-Kolenikov.{p_end}
{p 4 7}{bf:{help pea_figure4:[PEA] pea figure4}} 

{p 4 7}{opt Figure 5}: Decomposition of poverty changes: growth and redistribution: Huppi-Ravallion .{p_end}
{p 4 7}{bf:{help pea_figure5:[PEA] pea figure5}} 

{p 4 7}{opt Figure 6}: GDP per capita GDP - Poverty elasticity.{p_end}
{p 4 7}{bf:{help pea_figure6:[PEA] pea figure6}}

{p 4 7}{opt Figure 7}: Welfare Figure with poverty line breakdowns for specified thresholds (e.g., `pline365`, `pline215`).{p_end}
{p 4 7}{bf:{help pea_figure7:[PEA] pea figure7}} 

{p 4 7}{opt Figure 8}: {p_end}
{p 4 7}{bf:{help pea_figure8:[PEA] pea figure8}} 

{p 4 7}{opt Figure 9a}: Inequality by year lines.{p_end}
{p 4 7}{bf:{help pea_figure9a:[PEA] pea figure9a}} 

{p 4 7}{opt Figure 9b}: GINI and GDP per capita scatter.{p_end}
{p 4 7}{bf:{help pea_figure9b:[PEA] pea figure9b}} 

{p 4 7}{opt Figure 10a}: Prosperity gap by year lines.{p_end}
{p 4 7}{bf:{help pea_figure10a:[PEA] pea figure10a}} 

{p 4 7}{opt Figure 10b}: Prosperity gap scatter (line-up).{p_end}
{p 4 7}{bf:{help pea_figure10b:[PEA] pea figure10b}} 

{p 4 7}{opt Figure 10c}: PG (survey) and GDP per capita scatter.{p_end}
{p 4 7}{bf:{help pea_figure10c:[PEA] pea figure10c}} 

{p 4 7}{opt Figure 12}: Decomposition of growth in prosperity gap.{p_end}
//todo: add comparability, add the combine graph options
{p 4 7}{bf:{help pea_figure12:[PEA] pea figure12}}

{p 4 7}{opt Figure 13}: Distribution of welfare by deciles{p_end}
//todo: add comparability, add the combine graph option
{p 4 7}{bf:{help pea_figure13:[PEA] pea figure13}} 

{p 4 7}{opt Figure 14}: Multidimensional poverty: Multidimensional Poverty Measure (World Bank).{p_end}
{p 4 7}{bf:{help pea_figure14:[PEA] pea figure14}} 

{p 4 7}{opt Figure 15}: Climate risk and vulnerability.{p_end}
{p 4 7}{bf:{help pea_figure15:[PEA] pea figure15}} 

{title:Options}

{p 4 4 2}
{opt natwelfare(varname)}  specifies the variable representing national welfare.

{p 4 4 2}
{opt natpovlines(varlist)} lists the national poverty lines to be analyzed.

{p 4 4 2}
{opt pppwelfare(varname)} specifies the variable representing welfare in PPP terms.

{p 4 4 2}
{opt ppppovlines(varlist)} lists the poverty lines in PPP terms.

{p 4 4 2}
{opt year(varname)} specifies the variable for survey years.

{p 4 4 2}
{opt setting(string)} specifies the setting configuration (e.g., {it:GMD}). 

{p 4 4 2}
{opt excel(string)} specifies the path to save the output Excel file. If not provided, a temporary file will be used.

{p 4 4 2}
{opt byind(varlist)} specifies additional group indicators for disaggregation.

{p 4 4 2}
{opt age(varname)}, {opt male(varname)}, {opt hhhead(varname)}, {opt edu(varname)}, etc., 
specify demographic or household characteristics for additional breakdowns.

{p 4 4 2}
{opt oneline(varname)} and {opt onewelfare(varname)} define the welfare line and welfare variable 
for a single-line analysis.

{p 4 4 2}
{opt country(string)} specifies the country code for the analysis.

{p 4 4 2}
{opt within(integer)} sets the maximum number of years for comparability. Default is 3, and the program 
disallows values greater than 10.

{p 4 4 2}
{opt scheme(string)} and {opt palette(string)} define the graphical scheme and color palette for the figures.

{title:Remarks}

{pstd}
The program performs several data quality checks, including missing observations and weight 
verifications. It also ensures that the inputs meet the requirements for each figure type. 

{pstd}
Each figure (e.g., 1–10) is generated sequentially and saved to the specified Excel file or a temporary file.

{title:Examples}
