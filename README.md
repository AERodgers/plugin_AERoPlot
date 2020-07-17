# AERoPlot - a Praat plug-in for plotting data

AERoPlot allows you to generate elegant plots from data in Praat.

To use it, you need to [download Praat](https://www.praat.org) onto your computer. Then:
1. Click on the **clone or download** button above followed by **download ZIP**.
2. Download and unzip the file.
3. Copy the **plugin_AERoplot-master** folder and *all* its contents into the **Praat preferences directory**.

    ([Click on this link](http://www.fon.hum.uva.nl/praat/manual/preferences_directory.html) for guidelines on how to locate this directory on your computer.)

Once you have installed the plugin, you can access it from **New** > **graphic...** in the objects window.

There are currently four plot types:
1. F1-F2 plots;
2. Formant plots for showing 2+ formants (called "Ladefoged plots" here);
3. Formants-over-time plots, similar to the Ladefoged plots, but with time on the x axis;
4. C3P-o-grams, which plot F0 contours along with a second parameter indicated by line size and colour intensity (CPP, H2-H1 of the differentiate glottal source...)

By default, images are saved to a folder on your desktop called "AERoPlot_Images"

The plugin has functionality, including:
 * the ability to display Hertz logarithmically or along the bark scale;
 * memory - menus remember your choices from across different sessions;
 * an automatic legend function, which choses the optimal location for the plot on the chart;
 * several colour palette choices and colour sorting methods (default, by in order of maximal difference in the colour space, etc.);
 * cross-hatching to help distinguish elements;
 * shading and outlining of text and plot elements to make them more readable;
 * the ability to categorise data by main and sub categories and to use tertiary filters to exclude unnecessary data;
 * a high degree of customisability for displaying / hiding many plot elements.

There are quite a few for not-so-obvious quality-of-life features and many ways to customise your plot in terms of content and appearance. However, due to the nature of Praat's UI (or due to my ability to exploit it), I have avoided adding too many, as this would lead to menu bloat. Therefore, some things such as font size are fixed.

There are no detailed instructions yet, but I will produce these in time along with a more comprehensive list of the plugin's functionality.

For now,  I recommend you just to muck around with it. And - of course - if you find any bugs or have any suggestions for improvements, please do let me know.


Known issues / future plans:
* The option to display only outliers in the box plot component of the Ladefoged does not function yet.
* The add / change colour options is not storing changes as intended.
* There will be an easily accessible archive to make facilitate the reproduction and alteration of previous plots.
* Intelligibilty / intuitiveness of menus will be improved (feedback much appreciated and needed here).
___

The plugin is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

The plugin is distributed in the hope that it will be useful, but WITHOUT ANY  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this. If not, see <http://www.gnu.org/licenses/>.
