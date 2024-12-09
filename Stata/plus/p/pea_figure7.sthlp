{smcl}
{* 10Nov2024}{...}
{hline}
help for {hi:pea figure7}{right:November 2024}
{hline}

// Figure 7: Welfare Figure with poverty line breakdowns for specified thresholds (e.g., `pline365`, `pline215`).


    Help File for `pea_figure7`

    Title: Welfare Figure with Poverty Line Breakdowns for Specified Thresholds 

    Description:
    `pea_figure7` generates welfare visualizations with breakdowns for specified poverty thresholds,
    such as `pline365`, `pline215`. This program performs necessary data preparation,
    computes poverty statistics, and exports figures/poverty analysis results.

    Syntax:
    pea_figure7 [if] [in] [aw pw fw], 
        [NATWelfare(varname numeric) 
        NATPovlines(varlist numeric) 
        PPPWelfare(varname numeric) 
        PPPPovlines(varlist numeric) 
        Year(varname numeric) 
        FGTVARS 
        LINESORTED 
        NONOTES 
        age(varname numeric) 
        male(varname numeric) 
        hhhead(varname numeric) 
        edu(varname numeric) 
        urban(varname numeric) 
        setting(string) 
        scheme(string) 
        palette(string) 
        excel(string) 
        save(string)]

    Options:
    - NATWelfare(varname numeric): Specifies the variable name corresponding to national welfare.
    - NATPovlines(varlist numeric): List of numeric poverty thresholds used for national poverty calculation.
    - PPPWelfare(varname numeric): Specifies the variable name for purchasing power parity welfare measures.
    - PPPPovlines(varlist numeric): List of numeric PPP poverty thresholds for PPP calculations.
    - Year(varname numeric): Name of the variable indicating the year in your dataset.
    - FGTVARS: Calculates Foster-Greer-Thorbecke (FGT) poverty measures.
    - LINESORTED: Orders poverty thresholds for consistency.
    - NONOTES: Omits default text/notes from the graph.
    - age(varname numeric): Variable that defines age groups for subgroup analysis.
    - male(varname numeric): Variable defining gender for subgroup analysis.
    - hhhead(varname numeric): Indicates whether an individual is a household head.
    - edu(varname numeric): Specifies the education variable for subgroup breakdowns.
    - urban(varname numeric): Urban/Rural classification variable for subgroup analysis.
    - setting(string): Defines specific setting options like `GMD`.
    - scheme(string): Graph/plotting scheme (not implemented in full).
    - palette(string): Color palette for visualization customization.
    - excel(string): Path for exporting results in Excel format.
    - save(string): File path for saving computed data.

    Output:
    The program creates:
    - Scatter plots visualizing welfare statistics by specified poverty thresholds.
    - Poverty rates by groups with detailed statistics saved into Excel if specified.

    Example:
    pea_figure7 if year==2022, 
        NATWelfare(welfare) NATPovlines(365 215) 
        PPPWelfare(pppwelfare) PPPPovlines(365 215) 
        Year(year) FGTVARS

    Notes:
    This program uses survey data to compute poverty rates and FGT measures by income thresholds.
    When provided with specific poverty thresholds (national or PPP-based), it generates visualization outputs.
    The graphs are exported in Excel format unless specified otherwise.
