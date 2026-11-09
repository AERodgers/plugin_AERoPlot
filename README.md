# AERoPlot - a Praat plug-in for plotting data

AERoPlot allows you to generate elegant plots from data in Praat.

To use it, [download Praat](https://www.praat.org). Praat 6.2.0 or later is recommended. The plugin's version check accepts Praat 6.0.60 or later, but compatibility with all older versions has not been verified.

1. Download this repository as a ZIP and unzip it.
2. Copy the extracted **plugin_AERoPlot-master** folder and *all* its contents into the **Praat preferences folder**. (The folder name may differ if the ZIP was downloaded from a different branch.)
3. Restart Praat.

    ([Click on this link](https://praat.org/manual/preferences_folder.html) for guidelines on how to locate this folder on your computer.)

In Praat's Objects window:
* Select a **Table** to access the F1-F2, Ladefoged, and Formants-over-time plots under **AERoPlot**.
* Select a **Sound** to access **C3P-o-Gram**, or select a Sound and TextGrid to include a TextGrid tier. With both selected, **AERoPlot** also offers conversion of nested TextGrid tiers to a data table.
* Use **New > AERoPlot > Load example sound and text grid...** to load the example Sound and TextGrid.

There are currently four plot types:
1. F1-F2 plots;
2. Formant plots for showing 2+ formants (called "Ladefoged plots" here);
3. Formants-over-time plots, similar to the Ladefoged plots, but with time on the x axis;
   NB: This function is undergoing repairs and its full interactive workflow still needs validation.
4. C3P-o-grams, which can plot F0 contours with a secondary parameter indicated by point size and colour intensity: cepstral peak prominence (CPP), intensity residual, H1-H2 of the differentiated glottal pulse, or harmonicity.

The F1-F2, Ladefoged, and Formants-over-time plots save PNG images, when requested, to `plugin_AERoPlot/data/AERoPlot_Images` inside your [Praat preferences folder](https://praat.org/manual/preferences_folder.html). The **Save folder** field accepts an absolute path and is remembered separately for each plot type; leave it blank to restore the default. Existing saved folder settings are retained until changed or cleared. Missing folders are created when saving, and existing image files are preserved by adding a numbered suffix. The **Save name** field is a filename, not a path; `.png` is added if needed.

C3PoGram draws in Praat's Picture window; use the Picture window's save or export commands to save it.

The plugin has functionality, including:
 * the ability to display Hertz logarithmically or along the bark scale;
 * memory - menus remember your choices from across different sessions;
 * an automatic legend function, which choses the optimal location for the plot on the chart;
 * several colour palette choices and colour sorting methods (default, by in order of maximal difference in the colour space, etc.);
 * cross-hatching to help distinguish elements;
 * shading and outlining of text and plot elements to make them more readable;
 * the ability to categorise data by main and sub categories and to use tertiary filters to exclude unnecessary data;
 * a high degree of customisability for displaying / hiding many plot elements.

There are quite a few not-so-obvious quality-of-life features and many ways to customise your plot in terms of content and appearance. Controls are kept compact to avoid menu bloat.

**Legacy manual:** The [v1.4 PDF manual](AERoPlot_v.1.4_Manual.pdf) remains available as a guide to plotting options, but its installation instructions, menus, and some features may be outdated. Use this README for current installation and access instructions. The [editable Word version](AERoPlot_v.1.4_Manual.docx) is also included for a future update.

C3PoGram can draw an F0 contour with or without a secondary parameter, intensity alone, or a background without a contour. The spectrogram and waveform can be enabled separately. Lower H1-H2 values produce larger, more saturated points. The time-axis tick spacing adjusts to the displayed duration. Window width controls the plot width in inches; spectrogram pre-emphasis is fixed at 8 dB/octave. C3PoGram scales the selected Sound object to 70 dB in Praat; this does not change the original sound file.

C3PoGram and optional formant extraction from a TextGrid warn before processing recordings longer than 60 seconds. To change the threshold, edit `warningSeconds` in the `warnLongRecording` procedure in [the general function bank](plotScripts/_genFnBank.praat).

For formants-over-time plots with relative time, each combination of main factor and repetition must have exactly one row for the chosen reference element. If repetitions are present, provide a repetition column; missing or duplicate reference times are reported instead of producing incorrectly aligned data.

The Praat scripts in [tests](tests) provide batch tests for C3PoGram, shared helpers, and image saving. They can be run with Praat's `--run` option; `--no-plugins --no-pref-files` avoids loading installed plug-ins or changing preferences during testing. The image-save test takes an absolute path to a test folder that does not yet exist and leaves its test files there for inspection and removal.

Try the [sample datasets](example), including the Peterson and Barney (1952) table. Load a table into Praat and select it before choosing a table plot. For the Peterson and Barney data, use the columns "IPA", "Type", and "Sex" as grouping factors. When running a table-plot script without a selected Table, entering `0` in its object-number or file-path field also loads the Peterson and Barney data.


Known issues / future plans:
* ~~The option to display only outliers in the box plot component of the Ladefoged does not function yet.~~
* ~~The add / change colour options is not storing changes as intended.~~
* The full interactive Formants over Time workflow still needs validation.
* There will be an easily accessible archive function to make facilitate the reproduction and alteration of previous plots.
* Intelligibilty / intuitiveness of menus will be improved (feedback much appreciated and needed here).
___

The plugin is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

The plugin is distributed in the hope that it will be useful, but WITHOUT ANY  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this. If not, see <http://www.gnu.org/licenses/>.
