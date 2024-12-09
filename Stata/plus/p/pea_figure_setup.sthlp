{smcl}
{* 10Dec2024}{...}
{hline}
help for {hi:pea figure_setup}{right:December 2024}
{hline}

{title:Title}

{p 4 15}
{bf:pea figure_setup} — Set up figure schemes and color palettes for PEA projects.

{title:Syntax}

{p 4 15}
{opt pea_figure_setup} 
[{opt if} {it:exp}] 
[{opt in} {it:exp}] 
[{opt ,}{opt groups(string)} {opt scheme(string)} {opt palette(string)}]

{title:Description}

{p 4 4 2}
{opt pea figure_setup} is a program designed to streamline the process of setting up consistent figure aesthetics for PEA (Poverty and Equity Analysis) projects. It allows users to define and apply custom figure schemes, color palettes, and group-based color assignments, ensuring professional and cohesive visual outputs.

{title:Options}

{p 4 4 2}
{opt groups(string)} specifies the number of groups (e.g., categories or series) for which colors should be assigned. This determines the size of the color palette generated.

{p 4 4 2}
{opt scheme(string)} specifies the figure scheme to be used. If not specified, the program defaults to {opt white_tableau}.

{p 4 4 2}
{opt palette(string)} specifies the color palette to be used. If not specified, the program defaults to {opt tab10}. For other available palettes, see the {opt colorpalette} documentation.


{title:Details}

{p 4 4 2}
The program performs the following tasks:

{p 4 4 2}
- Sets the figure scheme to the specified or default value.

{p 4 4 2}
- Generates a color palette using the {opt colorpalette} command. If the {opt groups()} option is specified, it restricts the palette to the specified number of colors.

{p 4 4 2}
- Stores the generated color palette as a global macro ({opt colorpalette}) and individual colors as global macros ({opt col1}, {opt col2}, etc.).

{p 4 4 2}
- For the default palette ({opt tab10}), the program appends a gray color ({opt 148 148 148}) as the last entry in the palette.


{title:Examples}

{p 4 4 2}
To set up a figure with the default scheme ({opt white_tableau}) and palette ({opt tab10}): 

{p 4 4 2}
pea figure_setup

{p 4 4 2}
To use a specific palette (e.g., {opt viridis}) for 5 groups:

{p 4 4 2}
pea figure_setup, palette(viridis) groups(5)

{p 4 4 2}
To set a custom scheme and palette:

{p 4 4 2}
pea figure_setup, scheme(s2mono) palette(coolwarm)

