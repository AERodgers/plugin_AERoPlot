# AERoPlot - a Praat plug-in for plotting data

AERoPlot allows you to generate elegant plots from data in Praat. It can create four types of figure.

## **Download and installation**
To use it, [download Praat](https://www.praat.org). Praat 6.2.0 or later is recommended. The plugin's version check accepts Praat 6.0.60 or later, but compatibility with all older versions has not been verified.

1. Download this repository as a ZIP and unzip it.

2. Copy the extracted **plugin_AERoPlot** folder and *all* its contents into the **Praat preferences folder**.  
    - The folder name may differ if the ZIP was downloaded from a different branch.
    - [Click on this link](https://praat.org/manual/preferences_folder.html) for guidelines on how to locate this folder on your computer.
3. Restart Praat.
4. **Note:** The first time you open Praat after installing the plug-in, it may take up to 10 seconds to open. This will only happen one.

## **Functionality**

### **PitchPlus and Spectrogram**
The contextual **AERoPlot** menu offers **PitchPlus** and **Spectrogram** when you select a Sound object, with or without a TextGrid. PitchPlus was previously called C3PoGram.

This can generate an **F0 contour** and a possible **secondary parameter** represented by point size and colour intensity.

Possible secondary parameters include:

* **Cepstral peak prominence (CPP)**
* **Intensity residual**
* **H1-H2 of the differentiated glottal pulse**
* **Harmonicity**

It can also draw the **intensity contour** alone or just the **spectrogram (and waveform)** without any contour.

**Spectrogram** always draws a spectrogram and offers a simplified interface without contour settings. It supports the same waveform and TextGrid options as PitchPlus.
 
### **Plots from data tables**

Create three plot types from tables generated with **Create Table**, or from any well-formed, compatible table or table file:

* **F1–F2 plots**
* **Formant plots** (2+ formants; called “Ladefoed plots” here)
* **Formants-over-time plots** (similar to Ladefoed plots, with time on the x-axis)

Tables created from **Create Table** are very useful for extracting standard acoustic and TextGrid parameters.

## A Quick tutorial using the sample data  
In Praat's Objects window:
* Use **Praat > AERoPlot > Load example sound and text grid** to load the example Sound and TextGrid.
* Select both the Sound and TextGrid objects
* Use **Create Table** to convert the nested TextGrid tiers to a data table
* Select the **Table** to access the F1-F2, Ladefoged, and Formants-over-time plots under **AERoPlot**.
* Select a **Sound** to access **PitchPlus** or **Spectrogram**, or select a Sound and TextGrid to include a TextGrid tier.
(Note this is more suited to short sound files rather than the full sample data files.)

### How Create Table reads a nested TextGrid

Create Table turns the labels of a TextGrid into one table row per item of the
**base tier**.

* **Base tier**: the finest tier, with one row per interval or point. For example,
  with tiers Speaker, Type, Segment, IPA and Element, where IPA points sit inside
  Segment intervals, choose IPA or Element as the base tier. A Segment base would
  give one row per segment, so segments with one or two formant points could not
  fill the same columns.
* **Other tiers**: tiers that contain the base tier (here Speaker, Type and
  Segment). Each base item takes the label of the item that contains it, and each
  tier becomes a column. Tiers that lie inside the base tier would give empty
  columns, so they are not offered (Windows) or are rejected with a message.
* **Duration tier** (optional): any interval tier. It adds a `[tierName]_dur`
  column in seconds with the length of the interval containing each row.
* **Formants** (optional): measured on the base tier, at each point for a point
  tier, or averaged over the interval for an interval tier.

In the original **Create Table** dialog, tier fields
accept either a tier name or its number in the TextGrid. Separate multiple
additional tiers with commas. Numeric tier names can be confused with tier
positions; if an entry matches two different tiers, rename the numeric tier
before continuing. Duplicate tier names also need to be made unique.

Formants are measured on the base tier: at each point for a point tier, or as
the mean of the defined values (in the chosen Hertz or Bark scale) across the
interval for an interval tier. To get one row per point inside a longer
segment, use the finest point tier as the base tier. The optional **Duration
tier** (any interval tier) adds a `[tierName]_dur` column in seconds, holding
the length of the interval that contains each row. Older saved settings for the
separate point-tier field are ignored.

When both a Sound and TextGrid are selected, both interfaces offer separate dropdowns for the interval tier used to crop the plot to its first and last non-empty intervals, and the tier shown with the spectrogram. Point tiers are available for display but not cropping. Choose **Do not crop** to use the full Sound duration, or **No TextGrid** in the display menu to hide the tier. The boundary checkbox controls dotted extensions of tier boundaries or points over the plot; separators in the tier itself remain visible. The TextGrid font can be selected independently; **Times** uses Praat's Times serif face. Axis and TextGrid text use 12 pt, and the title uses 16 pt. Without a selected TextGrid, the TextGrid controls are hidden and the full Sound duration is used. The interfaces share remembered general settings and the boundary checkbox; TextGrid tier selections and font are not remembered between runs. Existing PitchPlotPlus or C3PoGram settings are migrated on first use, leaving the old settings file intact. Spectrogram does not change PitchPlus's contour or spectrogram-toggle preferences.

Choose **Draw** to draw and reopen the settings with all choices intact, including TextGrid choices for the current run. Each redraw replaces the previous picture. Choose **Draw & Exit** to draw and finish, or **Cancel** to finish without drawing again.

You can also practise using the formant Datasets from the Literature, which are baked into Praat (`New --> Table --> Datasets from the literature`). For example, if you use the Peterson and Barney (1952) dataset, use the columns "IPA", "Type", and "Sex" as grouping factors.


## Saving Images
The F1-F2, Ladefoged, and Formants-over-time plots save PNG images, when requested, to `plugin_AERoPlot/data/AERoPlot_Images` inside your [Praat preferences folder](https://praat.org/manual/preferences_folder.html). The **Save folder** field accepts an absolute path and is remembered separately for each plot type; leave it blank to restore the default. Existing saved folder settings are retained until changed or cleared. Missing folders are created when saving, and existing image files are preserved by adding a numbered suffix. The **Save name** field is a filename, not a path; `.png` is added if needed.

PitchPlus and Spectrogram draw in Praat's Picture window; use the Picture window's save or export commands to save them.

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

PitchPlus can draw an F0 contour with or without a secondary parameter, intensity alone, or a background without a contour. The spectrogram and waveform can be enabled separately. Lower H1-H2 values produce larger, more saturated points. The time-axis tick spacing adjusts to the displayed duration. Window width controls the plot width in inches; spectrogram pre-emphasis is fixed at 8 dB/octave. Both interfaces scale the selected Sound object to 70 dB in Praat; this does not change the original sound file.

PitchPlus, Spectrogram and optional formant extraction from a TextGrid warn before processing recordings longer than 60 seconds. To change the threshold, edit `warningSeconds` in the `warnLongRecording` procedure in [the general function bank](plotScripts/_genFnBank.praat).

For formants-over-time plots with relative time, each combination of main factor and repetition must have exactly one row for the chosen reference element. If repetitions are present, provide a repetition column; missing or duplicate reference times are reported instead of producing incorrectly aligned data.

The Praat scripts in [tests](tests) provide batch tests for shared helpers and image saving, plus interactive PitchPlus and Spectrogram smoke tests. For batch tests, put Praat's options before the script filename, for example `Praat --no-plugins --no-pref-files --run tests/shared_helpers.praat`; these flags avoid loading installed plug-ins or changing preferences. The image-save test also takes an absolute path to a test folder that does not yet exist, for example `Praat --no-plugins --no-pref-files --run tests/image_save.praat C:\temp\aeroplot-image-test`, and leaves its test files there for inspection and removal. Run the plot smoke tests from Praat's GUI; their settings windows require choosing **Draw**, **Draw & Exit**, or **Cancel**.

On Windows, run `tests\table_tier_references_isolated.ps1` with `-Praat` and a
new `-TestDirectory` to check tier name and number resolution, ambiguity and
type errors, and vowel duration extraction. The runner also accepts an optional
`-SampleTextGrid` argument for the documented 35-row sample regression.

### Interfaces

Every workflow has the same functions behind up to three interfaces. Interface
code only collects settings; shared code validates them and does the work.

1. **Praat interface**: the native pause windows. It is the fallback
   whenever another interface cannot be used, and the default everywhere except
   on Windows.
2. **Command-line interface**: `plotScripts\cli_table.praat`,
   `cli_pitch_plus.praat` and `cli_spectrogram.praat` use Praat `form` fields so
   they can be run with `Praat --run`. All fields are positional, and the output
   path and an overwrite flag are always supplied, so nothing is asked
   interactively. Dropdown fields take the option text (for example `F1 and F2`
   or `300 dpi`), and tick boxes take 0 or 1. F1-F2, Ladefoged and
   formants-over-time forms are not available yet.
3. **Windows interface** (Create Table, PitchPlus, Spectrogram and F1-F2 only;
   the default on Windows): see below.

Choose between the Praat and Windows interfaces with **Praat > AERoPlot >
Use Praat interface** or **Use Windows interface**. These two entries appear
on Windows only; elsewhere the Praat interface is the only one, so there is
nothing to choose. Until you choose, Windows uses the Windows interface when it
is usable. The choice
is remembered in `data\vars\ui_mode.txt`. If Windows is chosen but not usable
(not Windows, Praat older than 6.4.60 or the helper has not been built), the
Praat interface is used silently. Ladefoged and formants-over-time always
use the Praat interface. F1-F2 uses the Windows interface when one Table is
selected and the Praat interface otherwise (for example to read a table file).

When Praat starts on Windows the plug-in also launches the helper once in the
background, so that the first dialog is not delayed by Windows checking the
program.

Optional text fields (such as the duration tier, title and
TextGrid in the PitchPlus and Spectrogram forms) are switched off by leaving
them blank or entering `none` or `null` in any capitalisation. Required fields
never accept these values, and `0` is not an off value.

Tiers can be given by name or number in Create Table and the PitchPlus and
Spectrogram forms. The F1-F2, Ladefoged and formants-over-time dialogs accept a
Table column header or column number in their column fields. If a header is
itself a number that differs from its position, the number is ambiguous; use
descriptive headers. A missing column is reported with the list of real headers.

`tests\interface_helpers.praat` (run with `--pref-dir` set to a new folder and
that folder as its argument) checks off values, column resolution and the saved
preference. `tests\cli_forms_isolated.ps1` runs the command-line forms against
sample files (`-Praat`, a new `-TestDirectory` and `-SampleDirectory`).

The main native Praat dialog procedures for F1-F2, Ladefoged, formants over
time, and Create Table live in separate `_praat_*_ui.praat` files. PitchPlus and
Spectrogram share a plotting script with separate native, Windows and form
dialog procedures. These adapters still use the existing shared variables and
settings; the shared filtering, colour, saving and warning prompts have not yet
been separated from their processing procedures.

On Windows, `tests\praat_ui_refactor_isolated.ps1` exercises the native
PitchPlus and Spectrogram draw-and-exit paths and opens and exits the initial
native dialogs for the other four workflows. It runs in an interactive desktop
and requires a new test directory:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\praat_ui_refactor_isolated.ps1 -Praat "C:\Program Files\Praat\Praat.exe" -TestDirectory "C:\temp\aeroplot-native-ui-test"
```

The test saves PitchPlus and Spectrogram images in the test directory for
comparison. It does not yet test the complete table or formant-plot workflows.

## Experimental Windows interfaces

These Windows Forms interfaces are **proofs of concept, not a finished
installer**. They are launched from Praat, while Praat remains responsible for
processing and drawing. The original Praat dialogs remain available.

To try this source version on Windows:

1. Use Praat 6.4.60 or newer. The prototype was tested with Praat 6.4.60.
2. Before copying the plugin to the Praat preferences folder, double-click
   `windows-ui\build.cmd` in the extracted plugin folder. It builds the shared
   Windows dialog helper using the .NET Framework 4 compiler; the compiler must
   be present. The generated `windows-ui\bin\AERoPlotWindowsUI.exe` is not
   included in source downloads. If building fails, the original Praat actions
   remain available.
3. Copy the complete folder, including `windows-ui\bin`, into the Praat
   preferences folder as described above and restart Praat.

### Create Table

Select one Sound and one TextGrid, choose **Use Windows interface** as above,
then choose **Create Table** under **AERoPlot**. The dialog lists the actual tier names and
creates a Table in the same Praat session.

Choose a base tier and, optionally, additional tiers. Additional tiers are
processed in their TextGrid order. The dialog also offers an optional
**Duration** tier, formant extraction (F1 to F4, in Hertz or Bark) with the
`To Formant (Burg)` settings, and remembers its settings between runs. The
settings are shown in two columns so the dialog fits on one screen; the
formant analysis fields appear only when formants are selected. Tier names
must be unique and cannot be empty, contain leading/trailing or repeated
spaces, commas, quotes, wildcard characters, tabs or line breaks. Table names
must start with an English letter and use only English letters, digits and
underscores. The Windows dialog cannot handle very long lists of tier names. Use the
original action if these restrictions are unsuitable.

Praat waits while the Windows dialog is open, so its windows will not respond
until the dialog is closed. Cancel leaves the original selection intact. If
Praat is forcibly closed while the dialog is open, close the dialog separately.
This synchronous design avoids sending a command to a different Praat session,
but needs further usability and error-handling work before release.

### F1-F2 plot

With one Table selected, **F1-F2 plot** opens a Windows dialog that stays open
while Praat remains usable.

* **Data**: dropdowns of the table's columns for the main and secondary factors
  and for F1 and F2. F1 and F2 are pre-selected from numeric columns whose names
  look like them (`F1`, `f1`, `Formant1`, `F_1_Hz`, but not `F10`). Bark is
  chosen when the names say Bark or all F2 values are below 30.
* **Include**: tick the levels of each factor to draw. **Add filter** keeps only
  chosen values of any other column.
* **Plot**: title, size, legend and the F1 and F2 ranges (reset when the input
  units change).
* **Appearance**: **Font**, **Output units**, **Save folder** and **Colour
  settings** open small dialogs and show the current choice. Colour changes
  apply when you press **OK**; manual re-sorting, matching levels to colours
  and adding a scheme open their Praat windows immediately. Matched colours
  remain in use across redraws until changed or this dialog closes. Selecting
  another palette or sorting option clears the matches.
  **Restore the original default palette** restores the original colours and
  ordering without deleting custom schemes.
* **Layers**: how to mark data points, show means, the core level, the most
  prominent layer, ellipses and arrows.

**Draw** keeps the dialog open; **Draw & Exit** draws and closes it. **Save
image** saves the plot now shown in the Picture window under **Save name** in
the save folder; drawing alone never writes a file. Settings are remembered in
`data\vars\f1f1Plot.var`, shared with the Praat interface. The source is
`windows-ui\TablePlotUI.cs`, with the Praat side in
`plotScripts\_windows_f1f2_ui.praat`.
`tests\windows_f1f2_isolated.ps1` checks the dialog (Draw, Save image, Draw &
Exit, selection restored) with the same `-Praat` and `-TestDirectory`
arguments as the other Windows tests.

### PitchPlus and Spectrogram

With **Use Windows interface** chosen, the **PitchPlus** and **Spectrogram**
actions are available for a Sound, with or without a TextGrid, and open a
Windows dialog.
They expose the existing plot settings in a Windows dialog, including the
TextGrid crop/display controls when a TextGrid is selected. Spectrogram hides
PitchPlus-only controls. **Draw** redraws and keeps the dialog open; **Draw & Exit**
draws once and closes it. Praat's existing plotting procedures still do the
analysis and drawing; with **Use Praat interface** the same actions keep their
Praat pause forms.

The Windows dialog for PitchPlus and Spectrogram is not modal: Praat stays
usable while it is open. **Draw** sends a request to Praat, which draws the plot
in the Picture window; the dialog stays open and its buttons are disabled until
drawing finishes. **Draw & Exit** draws and then closes the dialog; **Cancel**
closes it without drawing. The dialog closes by itself if Praat exits. If an
input object is removed while the dialog is open, Praat reports it on the next
Draw. After each Draw the Objects selection is restored to what it was and the
Picture viewport covers the complete image, including any waveform and TextGrid
tier, at the selected width. Plot settings
use the existing PitchPlus settings file, so the interfaces share remembered
general settings.

Requests travel through Praat's `Message.txt` in its preferences folder, which
is shared by every sender. Avoid running other tools that message Praat at the
same time, and avoid starting other scripts while a plot is being drawn. Very
long recordings are drawn without the long-recording warning in this mode. The
explicit `windowsPitchPlusPrototype.praat` and `windowsSpectrogramPrototype.praat`
scripts, used by the tests, and the Create Table dialog remain synchronous.

`tests\windows_async_plot_isolated.ps1` checks the asynchronous plot dialog
(Praat responsive while open, repeated Draw, Draw & Exit, selection restored,
dialog closing when Praat exits). It takes the same `-Praat` and
`-TestDirectory` arguments as the other Windows tests.

The Windows UI tests in [tests](tests) require Windows, Praat, and the .NET
Framework compiler. `tests\windows_plot_ui_isolated.ps1` builds the helper into
a new isolated preferences folder and automates Table, PitchPlus, Spectrogram,
redraw, no-TextGrid, title, and cancellation checks. Run it from the repository
root in an interactive desktop, using a test directory that does not already
exist:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\windows_plot_ui_isolated.ps1 -Praat "C:\Program Files\Praat\Praat.exe" -TestDirectory "C:\temp\aeroplot-plot-ui-test"
```

The test opens and controls several Praat and dialog windows, and leaves its
isolated test files for inspection. The table prototype's example comparison
test is described below; all UI tests are separate from the existing batch
tests.

The example comparison test runs both interfaces on the example Sound and
TextGrid and compares the complete tab-separated Tables. It requires a Praat
GUI and an `AEROPLOT_TEST_RESULT` environment variable containing an absolute
path in a test directory; it writes the result and two `.tsv` files there. Run
it once with its `Base tier times only` argument set to `yes` and once with
`no`, using a different unused result path each time. In both dialogs choose
`Element` as the base tier and `Speaker`,
`Context`, and `Segment` as additional tiers, in that order. In the original
dialog, name the Table `native_comparison`, choose no formants, and clear the
duration-tier field. Match the timing checkbox to the script
argument in both dialogs. The test expects 35 rows and either 5 or 9 columns.

### Asynchronous integration experiment

The separate [isolated test](tests/windows_async_isolated.ps1) investigates
whether Praat can remain responsive while a companion dialog is open. It is
not a user-facing action. On Windows, with Praat and the .NET Framework 4
compiler installed, run it from the repository root in an interactive desktop:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\windows_async_isolated.ps1 -Praat "C:\Program Files\Praat\Praat.exe" -TestDirectory "C:\path\to\new-test-directory"
```

Choose a test directory that does not exist. The test creates it, copies Praat
into separate instance directories, builds a test helper there, and leaves
these files for inspection. It opens and controls several Praat and dialog
windows; avoid interacting with them during the test.

The test checks responsiveness, changed selection, two overlapping dialogs,
cancellation, errors after either original object is removed, and the test
driver refusing to send to a closed Praat process. The driver, not the helper,
delivers callbacks and checks whether Praat has closed; the helper does not
automatically close when Praat exits. The callback creates a simple test Table,
not the complete AERoPlot output.

Each test instance has its own preferences directory. Praat's Windows messaging
uses a shared `Message.txt`, so targeting a specific window is not sufficient
to avoid interference between normal instances or other senders. Safe callback
delivery, automatic helper lifecycle, simultaneous callbacks using shared
preferences, and edits to input objects while the dialog is open remain
unresolved. The Create Table Windows dialog remains synchronous; the PitchPlus
and Spectrogram dialogs use this mechanism (see above).

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
