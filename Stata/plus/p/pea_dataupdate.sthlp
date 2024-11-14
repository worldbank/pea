{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea dataupdate}{right:November 2024}
{hline}

{title:Title}

{p 4 15}
{bf:pea dataupdate} — updates data for multiple countries

{title:Syntax}

{p 4 15}
{cmd:pea dataupdate} 
[{it:weight}] 
[{cmd:if} {it:exp}] 
[{cmd:in} {it:exp}] 
[{cmd:,}
{opt datatype(string)} 
{opt pppyear(string)} 
{opt UPDATE}]

{title:Description}

{p 4 4 2}
{cmd:pea dataupdate} is a program that updates various datasets related to global poverty and economic indicators.The program checks if the data files for specified types (e.g., {it:MPM}, {it:PIP}, {it:SCORECARD}) exist and are up-to-date. If the data is outdated or missing, the program retrieves and processes new data from various sources such as the {it:PIP} tables, {it:MPM} datasets, and other relevant files. 
The updated data is saved in the user s personal directory under the "pea" folder for further analysis.

{title:Options}

{p 4 4 2}
{opt datatype(string)} specifies the type of data to update. Available options are:
   
    - MPM: Multidimensional Poverty Measure (MPM) data
    - PIP: Poverty and Inequality data
    - SCORECARD: Scorecard data
    - LIST: Country names and regions list
    - UNESCO: Placeholder for updating UNESCO data
    - CLASS: Placeholder for updating CLASS data

{p 4 4 2}  
{opt pppyear(string)} specifies the year for the PPP (Purchasing Power Parity) data to be used. The default year is 2017 if not provided.

{p 4 4 2}
{opt UPDATE} forces the program to update the data even if the files already exist and are up-to-date.


{title:Details}

{p 4 4 2}
The program performs the following tasks depending on the specified `datatype`:

{p 4 4 2}
- MPM: Updates the Multidimensional Poverty Measure data for the specified year and saves the data in the personal directory.

{p 4 4 2}	
- PIP: Retrieves and updates the Poverty and Inequality data (including GDP, population, income groups, and poverty rates) for the specified year, including the selected PPP year, and merges various datasets to create a comprehensive file.

{p 4 4 2}	
- SCORECARD: Placeholder for updating scorecard data (currently not implemented).

{p 4 4 2}	
- LIST: Updates the list of country names and regions from the PIP database.

{p 4 4 2}	
- UNESCO and CLASS: Placeholders for updating UNESCO and CLASS data (currently not implemented).

{p 4 4 2}
The program performs checks to ensure data availability and retrieves data from specified sources if necessary. 
If data retrieval fails or if data for the requested PPP year is not available, an error message is displayed.

{title:Examples}

{p 4 4 2} 
To update the PIP data for the year 2023 and use PPP data from 2017:

{p 4 4 2}   
{cmd:. pea dataupdate, datatype(PIP) pppyear(2017)}

{p 4 4 2} 
To update the MPM data for the current year and force the update even if the file is up-to-date:

{p 4 4 2}   
{cmd:. pea dataupdate, datatype(MPM) UPDATE}

