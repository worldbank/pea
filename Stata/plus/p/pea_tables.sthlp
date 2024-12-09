{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea tables}{right:November 2024}
{hline}

{title:Title}

{p 4 15}
{bf:pea tables}  - Available Commands and Options

{title:Syntax}

{p 4 15}
{opt pea tables} 
[{it:weight}] 
[{opt if} {it:exp}] 
[{opt in} {it:exp}] 
[{opt ,} 
{opt natwelfare(varname numeric)}
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
{opt missing}
{opt oneline(varname numeric)}
{opt onewelfare(varname numeric)}
{opt country(string)}
{opt latest}
{opt within3}
{opt benchmark(string)}
{opt spells(string)}]{p_end}

{p 4 4 2}The command supports {opt aweight}s, {opt fweight}s, and {opt pweight}s. See {help weights} for further details.{p_end}

{title:Description}

{p 4 4 2}{opt pea tables} generates a set of tables related to poverty, welfare, and income distribution. The command can generate various tables with user-defined specifications based on different variables like income, welfare measures, poverty lines, and socio-demographic characteristics.

{p 4 4 2}This command is part of a suite of `pea` commands that provide flexibility in computing welfare and poverty statistics across a variety of groups, such as by region (urban/rural), year, and socioeconomic categories. It generates detailed tables summarizing these measures at the individual or household level.

{p 4 4 2}Tables generated may include poverty headcount ratios, income distributions, and aggregate poverty gaps. Additionally, it can generate statistics like the Watts index, Sen index, and Foster-Greer-Thorbecke indices.

{p 4 4 2}The following tables are available within the {opt pea tables} command, each serving a distinct purpose. For more detailed explanations of their contents and usage, see below:{p_end}

{p 4 7}{opt Table 1}: Summary table for welfare, poverty, and key demographic variables.{p_end}
{p 4 7}{bf:{help pea_table1:[PEA] pea table1}} 

{p 4 7}{opt Table 2}: Detailed table for welfare and poverty by urban/rural categories or subnational variables.{p_end}
{p 4 7}{bf:{help pea_table2:[PEA] pea table2}} 

{p 4 7}{opt Table 3}: Summary table by individual characteristics such as age, gender, education, and household head status.{p_end}
{p 4 7}{bf:{help pea_table3:[PEA] pea table3}} 

{p 4 7}{opt Table 4}: Summary table by individual characteristics such as age, gender, education, and household head status.{p_end}
{p 4 7}{bf:{help pea_table4:[PEA] pea table4}} 

{p 4 7}{opt Table 5}: Summary table by individual characteristics such as age, gender, education, and household head status.{p_end}
{p 4 7}{bf:{help pea_table5:[PEA] pea table5}} 

{p 4 7}{opt Table 6}: Table comparing welfare across different benchmark countries (e.g., ALB, HRV, XKX).{p_end}
{p 4 7}{bf:{help pea_table6:[PEA] pea table6}}

{p 4 7}{opt Table 7}: Welfare table with poverty line breakdowns for specified thresholds (e.g., `pline365`, `pline215`).{p_end}
{p 4 7}{bf:{help pea_table7:[PEA] pea table7}} 

{p 4 7}{opt Table 8}: Poverty and welfare statistics by urban area, including missing value analysis.{p_end}
{p 4 7}{bf:{help pea_table8:[PEA] pea table8}} 

{p 4 7}{opt Table 9}: Poverty and welfare statistics by urban area, including missing value analysis.{p_end}
{p 4 7}{bf:{help pea_table9:[PEA] pea table9}} 

{p 4 7}{opt Table 10}: Table comparing welfare with various poverty lines across benchmark countries, with options to include or exclude countries within 3 years.{p_end}
{p 4 7}{bf:{help pea_table10:[PEA] pea table10}} 

{p 4 7}{opt Table 11}: Table with longitudinal welfare statistics over multiple years, optionally with graphical output.{p_end}
{p 4 7}{bf:{help pea_table11:[PEA] pea table11}} 

{p 4 7}{opt Table 12}: Table with welfare measures broken down by various spells, showing changes over time for selected groups.{p_end}
{p 4 7}{bf:{help pea_table12:[PEA] pea table12}}

{p 4 7}{opt Table 13}: Longitudinal welfare table by urban/rural categories and selected spells.{p_end}
{p 4 7}{bf:{help pea_table13:[PEA] pea table13}} 

{p 4 7}{opt Table 14}: Detailed table for household-level welfare, including assets, services, and household characteristics.{p_end}
{p 4 7}{bf:{help pea_table14:[PEA] pea table14}} 

{p 4 7}{opt Table A2}: Table with welfare statistics by age, gender, education, and urban/rural, showing missing value patterns.{p_end}
{p 4 7}{bf:{help pea_table_A2:[PEA] pea table A2}}  


{title:Examples}

{p 4 4 2}
pea tables [aw=weight_p], c(GNB) natw(welfarenom) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline685) benchmark(ALB HRV XKX) missing setting(GMD) spells(2018 2021)

{p 4 4 2}
pea tables [aw=weight_p], c(ARM) natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) age(age) male(male) hhhead(head) edu(educat4) urban(urban) married(married) school(school) services(imp_wat_rec imp_san_rec electricity) assets(tv car cellphone computer fridge) hhsize(hsize) hhid(hhid) pid(pid) industrycat4(industrycat4) lstatus(nowork) empstat(empstat) onew(welfppp) oneline(pline685) benchmark(ALB HRV XKX) missing onew(welfppp) onel(pline365) spells(2015 2016; 2016 2017;2018 2025;2017 2025)

{p 4 4 2}
pea tables [aw=weight_p], c(ARM) natw(welfare) natp(natline natline2) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline685) benchmark(ALB HRV XKX) missing setting(GMD) spells(2015 2016; 2016 2017;2018 2025;2017 2025)









