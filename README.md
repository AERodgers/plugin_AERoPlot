# AERoPlot - a Praat plug-in for plotting data

AERoPlot allows you to generate elegant plots from data in Praat. It can create four types of figure.

## **Download and installation**
To use it, [download Praat](https://www.praat.org). Praat 6.2.0 or later is recommended. The plugin's version check accepts Praat 6.0.60 or later, but compatibility with all older versions has not been verified.

1. Download this repository as a ZIP and unzip it.

2. Copy the extracted **plugin_AERoPlot** folder and *all* its contents into the **Praat preferences folder**.  
    - The folder name may differ if the ZIP was downloaded from a different branch.
    - [Click on this link](https://praat.org/manual/preferences_folder.html) for guidelines on how to locate this folder on your computer.
3. Restart Praat.

## **Functionality**

### **C3P-o-grams**
The contextual **C3P-o-gram** menu appears when you select a Sound object or Sound + TextGrid object together.

This can generate an **F0 contour** and a possible **secondary parameter** represented by point size and colour intensity.

Possible secondary parameters include:

* **Cepstral peak prominence (CPP)**
* **Intensity residual**
* **H1-H2 of the differentiated glottal pulse**
* **Harmonicity**

It can also draw the **intensity contour** alone or just the **spectrogram (and waveform)** without any contour.
 
### **Plots from data tables**

Create three plot types from tables generated with **Create Table from nested TextGrid tiers**, or from any well-formed, compatible table or table file:

* **F1–F2 plots**
* **Formant plots** (2+ formants; called “Ladefoed plots” here)
* **Formants-over-time plots** (similar to Ladefoed plots, with time on the x-axis)

Tables created from **Create Table from nested TextGrid tiers** are very useful for extracting standard acoustic and TextGrid parameters.

## A Quick tutorial using the sample data  
In Praat's Objects window:
* Use **New > AERoPlot > Load example sound and text grid** to load the example Sound and TextGrid.
* Select both the Sound and TextGrid objects
* Use **Create Table from nested TextGrid tiers** to convert the nested TextGrid tiers to a data table
* Select the **Table** to access the F1-F2, Ladefoged, and Formants-over-time plots under **AERoPlot**.
* Select a **Sound** to access **C3P-o-Gram**, or select a Sound and TextGrid to include a TextGrid tier.
(Note this is more suited to short sound files rather than the full sample data files.)

When both a Sound and TextGrid are selected, C3PoGram offers separate dropdowns for the interval tier used to crop the plot to its first and last non-empty intervals, and the tier shown with the spectrogram. Point tiers are available for display but not cropping. Choose **Do not crop** to use the full Sound duration, or **No TextGrid** in the display menu to hide the tier. The boundary checkbox controls dotted extensions of tier boundaries or points over the plot; separators in the tier itself remain visible. The TextGrid font can be selected independently; **Times** uses Praat's Times serif face. Axis and TextGrid text use 12 pt, and the title uses 16 pt. Without a selected TextGrid, the TextGrid controls are hidden and the full Sound duration is used. C3PoGram remembers the boundary checkbox and other general settings between sessions; TextGrid tier selections and font are not remembered.

You can also practise using the formant Datasets from the Literature, which are baked into Praat (`New --> Table --> Datasets from the literature`). For example, if you use the Peterson and Barney (1952) dataset, use the columns "IPA", "Type", and "Sex" as grouping factors.


## Saving Images
The F1-F2, Ladefoged, and Formants-over-time plots save PNG images, when requested, to `plugin_AERoPlot/data/AERoPlot_Images` inside your [Praat preferences folder](https://praat.org/manual/preferences_folder.html). The **Save folder** field accepts an absolute path and is remembered separately for each plot type; leave it blank to restore the default. Existing saved folder settings are retained until changed or cleared. Missing folders are created when saving, and existing image files are preserved by adding a numbered suffix. The **Save name** field is a filename, not a path; `.png` is added if needed.

C3PoGram draws in Praat's Picture window; use the Picture window's save or export commands to save it.

## Quality of Life
The plugin has several quality of life features, including:
 * the ability to display Hertz logarithmically or along the bark scale;
 * memory - menus remember your choices from across different sessions;
 * an automatic legend function, which chooses the optimal location for the plot on the chart;
 * several colour palette choices and colour sorting methods (default, by in order of maximal difference in the colour space, etc.);
 * cross-hatching to help distinguish elements;
 * shading and outlining of text and plot elements to make them more readable;
 * the ability to categorise data by main and sub categories and to use tertiary filters to exclude unnecessary data;
 * a high degree of customisability for displaying / hiding many plot elements.

There are quite a few other not-so-obvious quality-of-life features and many ways to customise your plot in terms of content and appearance. Controls are kept compact to avoid menu bloat.

## Useful Things to know 

C3PoGram can draw an F0 contour with or without a secondary parameter, intensity alone, or a background without a contour. The spectrogram and waveform can be enabled separately. Lower H1-H2 values produce larger, more saturated points. The time-axis tick spacing adjusts to the displayed duration. Window width controls the plot width in inches; spectrogram pre-emphasis is fixed at 8 dB/octave. C3PoGram scales the selected Sound object to 70 dB in Praat; this does not change the original sound file.

C3PoGram and optional formant extraction from a TextGrid warn before processing recordings longer than 60 seconds. To change the threshold, edit `warningSeconds` in the `warnLongRecording` procedure in [the general function bank](plotScripts/_genFnBank.praat).

For formants-over-time plots with relative time, each combination of main factor and repetition must have exactly one row for the chosen reference element. If repetitions are present, provide a repetition column; missing or duplicate reference times are reported instead of producing incorrectly aligned data.

The Praat scripts in [tests](tests) provide batch tests for shared helpers and image saving, plus an interactive C3PoGram smoke test. For batch tests, put Praat's options before the script filename, for example `Praat --no-plugins --no-pref-files --run tests/shared_helpers.praat`; these flags avoid loading installed plug-ins or changing preferences. The image-save test also takes an absolute path to a test folder that does not yet exist, for example `Praat --no-plugins --no-pref-files --run tests/image_save.praat C:\temp\aeroplot-image-test`, and leaves its test files there for inspection and removal. Run the C3PoGram smoke test from Praat's GUI; its settings window requires choosing **Draw** or **Cancel**.

## Legacy Manual

[v1.4 PDF manual](AERoPlot_v.1.4_Manual.pdf) remains available as a guide to plotting options, but its installation instructions, menus, and some features may be outdated. Use this README for current installation and access instructions. The [editable Word version](AERoPlot_v.1.4_Manual.docx) is also included for a future update.


## Known issues / future plans:
* The full interactive Formants over Time workflow still needs validation.
* There will be an easily accessible archive function to make facilitate the reproduction and alteration of previous plots.
* Intelligibility / intuitiveness of menus will be improved (feedback much appreciated and needed here).
___

The plugin is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

The plugin is distributed in the hope that it will be useful, but WITHOUT ANY  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this. If not, see <http://www.gnu.org/licenses/>.
