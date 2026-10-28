cap program drop pea_figure_setup
program pea_figure_setup, rclass
version 18.0

*==============================================================================
* pea_figure_setup
* Configure graph schemes and color palettes used throughout the PEA package.
*==============================================================================
* Disclaimers & credits 
	
	*! version 0.1.1  12Sep2014
	*! Copyright (C) World Bank 2017-2024 
	*! Minh Cong Nguyen <mnguyen3@worldbank.org>; Sandra Carolina Segovia Juarez 
	* <ssegoviajuarez@worldbank.org>; Henry Stemmler <hstemmler@worldbank.org>.
	*! Modifications by Daylan Alberto Salmeron Gomez; Maria Fernanda Gonzalez Icaza

	* This program is free software: you can redistribute it and/or modify
	* it under the terms of the GNU General Public License as published by
	* the Free Software Foundation, either version 3 of the License, or
	* (at your option) any later version.

	* This program is distributed in the hope that it will be useful,
	* but WITHOUT ANY WARRANTY; without even the implied warranty of
	* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
	* GNU General Public License for more details.

	* You should have received a copy of the GNU General Public License
	* along with this program. If not, see <http://www.gnu.org/licenses/>.

* ==========================================================================
syntax [if] [in] [aw pw fw], [groups(string) scheme(string) palette(string)]

*----------------------------------------------------------------------
* Initialize graph scheme and color palette
*----------------------------------------------------------------------
* Use default PEA scheme if none is specified
    if ("`scheme'"=="") local scheme "white_tableau"
    if "`palette'"=="" {
        local defpal "1"
* Default World Bank color palette
        local palette `""52 167 242" "255 152 0" "102 74 182" "78 194 192" "243 87 142" "8 16 121" "12 124 104" "170 0 0" "221 218 33""'
    }
   set scheme `scheme'

* ----------------------------------------------------------------------
* Generate the requested number of colors from the palette
* ----------------------------------------------------------------------
    if "`groups'"~="" {
        colorpalette `palette', nograph n(`groups') noexpand
    }
    else {
        colorpalette `palette', nograph
    }

    local colorpalette `"`r(p)'"'

    * Append grey to the default palette for additional categories
    if "`defpal'" == "1" {
        local colorpalette `"`colorpalette' "148 148 148""'
    }
 
* ----------------------------------------------------------------------
* Store palette colors as globals for downstream figure routines
* ----------------------------------------------------------------------
   local collength : word count `colorpalette'
   forval col = 1 / `collength' {
        global col`col' : word `col' of `colorpalette'
    }
	    global colorpalette "`colorpalette'"

end
* ==========================================================================
