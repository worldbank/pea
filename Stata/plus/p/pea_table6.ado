*! version 0.1.1  12Sep2014
*! Copyright (C) World Bank 2017-2024 

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

//Table 6. Multidimensional poverty: Multidimensional Poverty Measure (World Bank)

cap program drop pea_table6
program pea_table6, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Welfare(varname numeric) Povlines(varname numeric) Year(varname numeric) core setting(string) excel(string) save(string) missing]
	
end