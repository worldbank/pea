# Poverty and Equity Assessments (PEA) <br/> Standardized core analytics package
Poverty and Equity Assessments are one of five core World Bank ASAs, focusing on studying the inclusiveness of the process of economics growth. Under the PEA3.0 program, the PEAs have been revamped to increase the impact and quality of the assessments. A key part of this revamp is a standardization of the core diagnostics and report structure. 
<br/>
Please see the PEA code manual and example Stata code in the package for more detailed information and instructions.

## Overview
This package contains Stata code to produce a comprehensive set of outputs to analyze trends in poverty, shared prosperity and inequality, as well as their drivers and profiles. The package contributes to the standardization of outputs, and intends to expedite analyses by creating a range of ready-to-use outputs.
There are three sets of Stata commands in the PEA package: 
* _pea core_ generates tables and figures for the standardized data annex that should be included in each PEA.
* _pea tables_ produces an extended set of tables, providing in-depth statistics on the state of poverty and shared prosperity over the last years, the profiles of those in poverty and vulnerable to falling into poverty, as well as drivers of changes.
* _pea figures_ produces an extended set of broad set of, including a comparison of poverty rates and GDP per capita with other countries, changes in poverty and inequality over time, population composition by income decile, profiles, or exposure and risk from climate-related hazards.

## Installation
Step 1: Download and prepare the PEA Stata package
* The package can be downloaded from this Github repository (click on “Code” on the top right and “Download ZIP”), and needs to be unzipped and stored on your device, in a location of your choosing.
* Within the package there are additional datasets in the folder “/pea/Stata/personal/**pea**”. These need to be saved in the ‘personal’ folder of your Stata system directory (the location of which can be found by entering _sysdir_ in Stata, e.g. c:/ado/personal/**pea**).
<br/>

Step 2: Access the survey data in GMD
* The pea codes are prepared for using survey data following the Global Monitoring Database (GMD) harmonization protocols. If the survey data for the country and year of analysis has already been harmonized and included in the GMD, it can be accessed in Stata using the datalibweb command.
* If the survey data has not yet been harmonized for the GMD, please reach out to the regional stats team for harmonization of the data (strongly recommended).
<br/>

Step 3: Create additional variables
* If the survey has been harmonized under the GMD dictionary, only a minimal set of additional variables need to be created by users. These include the desired poverty lines (national and international), and PPP-adjusted welfare aggregates.
<br/>

Step 4: Run the pea codes
* Once the data and pea package have been prepared, users can follow the example do-file in the package to run the commands. Note that the prepared data and the adopath to the pea package need to be called every time before a pea code is run (as in the example).
* Help files for each command can be accessed in Stata by typing _help pea core_, _help pea tables_, _help pea figures_, _help pea table1_, _help pea figure1_, etc.

## Example code syntax
pea core [aw=weight_p], c(GNB) year(year) 								natw(welfare) natp(natline) 								pppw(welfppp) pppp(pline365 pline215 pline685)					onew(welfppp) oneline(pline365)								byind(urban subnatvar) 								benchmark(CIV GHA GMB SEN)							setting(GMD) missing									spells(2018 2021)	
<br/>

pea tables [aw=weight_p], c(GNB)  year(year) 							natw(welfare) natp(natline) 								pppw(welfppp) pppp(pline365 pline215 pline685)					onew(welfppp) oneline(pline365)								byind(urban subnatvar) 									benchmark(CIV GHA GMB SEN)								setting(GMD) missing										spells(2018 2021)
<br/>

pea figures [aw=weight_p], c(GNB) year(year)							natw(welfare) natp(natline) 								pppw(welfppp) pppp(pline365 pline215 pline685) 					onew(welfppp) oneline(pline215) 								byind(urban) benchmark(CIV GHA GMB SEN AGA) 					spells(2010 2018; 2018 2021) 								setting(GMD) urban(urban)	within(3) 							comparability(comparability) welfaretype(CONS)					combine nonotes

## Additional notes
Access to the internet is needed to run the pea commands, as additional data files are downloaded using Stata’s pip command. All outputs are automatically created by running the three main commands, with minimum manual inputs needed from users. Codes can nevertheless be tailored to county contexts, for instance by specifying country-specific education or industry groups. The codes can be run for any number of surveys for a country. That is, the output produced can include a single year or multiple years to allow for easy comparisons of indicators over time.

## Authors
Minh Cong Nguyen <br/>
The World Bank  <br/>
mnguyen3@worldbank.org
<br/>

Sandra Carolina Segovia Juarez <br/>
The World Bank  <br/>
ssegoviajuarez@worldbank.org
<br/>

Henry Stemmler <br/>
The World Bank  <br/>
hstemmler@worldbank.org
