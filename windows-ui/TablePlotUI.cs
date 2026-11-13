using System;
using System.Collections.Generic;
using System.Drawing;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Windows.Forms;

// A table read from the tab-separated copy that Praat saves for the dialog.
internal sealed class PlotTable
{
    public string[] Columns;
    public List<string[]> Rows = new List<string[]>();
    private readonly Dictionary<int, bool> numeric = new Dictionary<int, bool>();

    public static PlotTable Load(string path)
    {
        string[] lines;
        using (var reader = new System.IO.StreamReader(path, new UTF8Encoding(false), true))
            lines = reader.ReadToEnd().Split(new[] { "\r\n", "\n" }, StringSplitOptions.None);
        if (lines.Length == 0 || lines[0].Length == 0)
            throw new ArgumentException("The table has no column headings.");
        var table = new PlotTable();
        table.Columns = lines[0].Split('\t');
        for (int i = 1; i < lines.Length; i++)
        {
            if (lines[i].Length == 0)
                continue;
            var cells = lines[i].Split('\t');
            if (cells.Length < table.Columns.Length)
                Array.Resize(ref cells, table.Columns.Length);
            table.Rows.Add(cells);
        }
        return table;
    }

    public static bool IsMissing(string value)
    {
        return string.IsNullOrEmpty(value) || value == "?" || value == "--undefined--";
    }

    public bool IsNumeric(int column)
    {
        bool known;
        if (numeric.TryGetValue(column, out known))
            return known;
        bool any = false, all = true;
        foreach (var row in Rows)
        {
            var value = row[column];
            if (IsMissing(value))
                continue;
            double parsed;
            if (!double.TryParse(value, NumberStyles.Float, CultureInfo.InvariantCulture, out parsed))
            {
                all = false;
                break;
            }
            any = true;
        }
        numeric[column] = any && all;
        return numeric[column];
    }

    public double MaximumValue(int column)
    {
        double maximum = double.NegativeInfinity;
        foreach (var row in Rows)
        {
            double parsed;
            if (!IsMissing(row[column]) &&
                double.TryParse(row[column], NumberStyles.Float, CultureInfo.InvariantCulture, out parsed) && parsed > maximum)
                maximum = parsed;
        }
        return maximum;
    }

    // Distinct values in the order in which they first occur.
    public List<string> Levels(int column)
    {
        var seen = new HashSet<string>();
        var levels = new List<string>();
        foreach (var row in Rows)
            if (seen.Add(row[column] ?? ""))
                levels.Add(row[column] ?? "");
        return levels;
    }

    public int IndexOf(string name)
    {
        return Array.IndexOf(Columns, name);
    }
}

internal static class TablePlotUI
{
    // Arguments: TABLEPLOT, settings file, temporary folder, Praat preferences folder,
    // callback script, Table object number.
    public static int Run(string[] args)
    {
        int tableId;
        if (args.Length != 6 || !System.IO.File.Exists(args[1]) || !System.IO.Directory.Exists(args[2]) ||
            !System.IO.Directory.Exists(args[3]) || args[4].IndexOf('"') >= 0 || !int.TryParse(args[5], out tableId))
            throw new ArgumentException("The F1-F2 plot interface received invalid input.");
        var settings = new Dictionary<string, string>();
        foreach (var line in System.IO.File.ReadAllLines(args[1], new UTF8Encoding(false)))
        {
            int tab = line.IndexOf('\t');
            if (tab > 0)
                settings[line.Substring(0, tab)] = line.Substring(tab + 1);
        }
        var info = new AsyncPlotInfo { PreferencesDirectory = args[3], CallbackScript = args[4], SoundId = tableId };
        info.PraatProcessId = PraatLink.ParentProcessId();
        if (info.PraatProcessId <= 0)
            throw new ArgumentException("The Praat process could not be identified.");
        string tablePath;
        if (!settings.TryGetValue("tableFile", out tablePath))
            throw new ArgumentException("The F1-F2 plot interface did not receive the table.");
        var table = PlotTable.Load(tablePath);
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        using (var window = new F1F2Window(table, settings, args[2], info))
            window.ShowDialog();
        return 0;
    }
}

internal sealed class F1F2Window : Form
{
    private static readonly string[] OutputUnitNames = {
        "Hertz", "Hertz (displayed re bark scale)", "Hertz (displayed logarithmically)",
        "kHz", "kHz (displayed re bark scale)", "kHz (displayed logarithmically)" };
    private static readonly string[] FontNames = { "Helvetica", "Times", "Courier", "Palatino" };
    private static readonly string[] FontSizes = { "8", "10", "12", "14", "16", "18" };
    private static readonly string[] ColourModes = {
        "No change", "Re-sort by brightness", "Re-sort by maximal perceptual difference",
        "Re-sort manually (a Praat window opens)", "Match levels to colours for this dialog (a Praat window opens)",
        "Restore the original default palette" };
    private const string None = "(none)";

    private readonly PlotTable table;
    private readonly string tempDirectory;
    private readonly AsyncPlotInfo async;
    private readonly Dictionary<string, string> initial;
    private readonly string tableName;
    private readonly string colourSession = Guid.NewGuid().ToString("N");

    private ComboBox mainFactor, secondFactor, f1Column, f2Column, inputUnits;
    private CheckedListBox mainLevels, secondLevels;
    private ListBox filterList;
    private readonly Dictionary<string, HashSet<string>> filters = new Dictionary<string, HashSet<string>>();
    private TextBox title, saveName;
    private NumericUpDown plotSize, minF1, maxF1, minF2, maxF2;
    private CheckBox showLegend, showArrows;
    private ComboBox tokenMarking, showMeans, coreLevel, topLayer, ellipses;
    private Label fontSummary, unitsSummary, folderSummary, colourSummary;
    private Button drawButton, drawExitButton, saveButton, colourButton;
    private int fontChoice, baseSize, outputUnits, colourMode;
    private bool addColourScheme;
    private string saveFolder;
    private int previousUnits;
    private bool loading = true;
    private bool refreshing;
    private bool busy;
    private bool activeColourMatch;
    private string matchedFactor;

    public F1F2Window(PlotTable table, Dictionary<string, string> initial, string tempDirectory, AsyncPlotInfo async)
    {
        this.table = table;
        this.initial = initial;
        this.tempDirectory = tempDirectory;
        this.async = async;
        tableName = Get("tableName", "Table");
        Text = "AERoPlot: F1-F2 plot (" + tableName + ")";
        Font = SystemFonts.MessageBoxFont;
        AutoScaleMode = AutoScaleMode.Font;
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;
        MinimizeBox = false;
        StartPosition = FormStartPosition.CenterScreen;
        ClientSize = new Size(900, 622);
        BuildControls();
        LoadInitialValues();
        loading = false;
        RefreshSummaries();
        RefreshLevels(mainLevels, mainFactor.Text, true);
        RefreshLevels(secondLevels, secondFactor.Text, true);
        RefreshCoreLevels();
        StartParentWatch();
        FormClosing += delegate (object sender, FormClosingEventArgs e)
        {
            if (busy && PraatLink.IsRunning(async.PraatProcessId))
            {
                e.Cancel = MessageBox.Show(this,
                    "A request is still running. Close this window anyway? You may still need to finish the Praat window.",
                    Text, MessageBoxButtons.YesNo, MessageBoxIcon.Warning) != DialogResult.Yes;
            }
        };
        FormClosed += delegate
        {
            string path = System.IO.Path.Combine(tempDirectory, "f1f2-colours-" + colourSession + ".txt");
            try { if (System.IO.File.Exists(path)) System.IO.File.Delete(path); }
            catch (System.IO.IOException e) { MessageBox.Show(e.Message, Text, MessageBoxButtons.OK, MessageBoxIcon.Warning); }
            catch (UnauthorizedAccessException e) { MessageBox.Show(e.Message, Text, MessageBoxButtons.OK, MessageBoxIcon.Warning); }
        };
    }

    private string Get(string key, string fallback)
    {
        string value;
        return initial.TryGetValue(key, out value) && value.Length > 0 ? value : fallback;
    }

    private int GetInt(string key, int fallback)
    {
        int value;
        return int.TryParse(Get(key, ""), NumberStyles.Integer, CultureInfo.InvariantCulture, out value) ? value : fallback;
    }

    private decimal GetNumber(string key, decimal fallback)
    {
        decimal value;
        return decimal.TryParse(Get(key, ""), NumberStyles.Float, CultureInfo.InvariantCulture, out value) ? value : fallback;
    }

    private static GroupBox Group(string text, int x, int y, int width, int height)
    {
        return new GroupBox { Text = text, Location = new Point(x, y), Size = new Size(width, height) };
    }

    private static Label Caption(string text, int x, int y, int width)
    {
        return new Label { Text = text, Location = new Point(x, y + 3), Size = new Size(width, 20), AutoEllipsis = true };
    }

    private static ComboBox Drop(int x, int y, int width, IEnumerable<string> items)
    {
        var combo = new ComboBox { Location = new Point(x, y), Width = width, DropDownStyle = ComboBoxStyle.DropDownList };
        combo.Items.AddRange(items.Cast<object>().ToArray());
        return combo;
    }

    private static NumericUpDown Number(int x, int y, int width, decimal minimum, decimal maximum, int decimals)
    {
        return new NumericUpDown { Location = new Point(x, y), Width = width, Minimum = minimum, Maximum = maximum, DecimalPlaces = decimals };
    }

    private void BuildControls()
    {
        var columns = table.Columns.Where(c => c.Length > 0).ToArray();

        var data = Group("Data", 10, 6, 430, 176);
        data.Controls.Add(Caption("Main factor (colour)", 12, 24, 140));
        mainFactor = Drop(160, 24, 250, columns);
        data.Controls.Add(mainFactor);
        data.Controls.Add(Caption("Secondary factor", 12, 54, 140));
        secondFactor = Drop(160, 54, 250, new[] { None }.Concat(columns));
        data.Controls.Add(secondFactor);
        data.Controls.Add(Caption("F1 column", 12, 84, 140));
        f1Column = Drop(160, 84, 250, columns.Where((c, i) => table.IsNumeric(table.IndexOf(c))));
        data.Controls.Add(f1Column);
        data.Controls.Add(Caption("F2 column", 12, 114, 140));
        f2Column = Drop(160, 114, 250, columns.Where((c, i) => table.IsNumeric(table.IndexOf(c))));
        data.Controls.Add(f2Column);
        data.Controls.Add(Caption("Input units", 12, 144, 140));
        inputUnits = Drop(160, 144, 250, new[] { "Hertz", "Bark" });
        data.Controls.Add(inputUnits);
        Controls.Add(data);

        var include = Group("Include", 10, 188, 430, 392);
        include.Controls.Add(Caption("Main factor levels", 12, 20, 190));
        mainLevels = new CheckedListBox { Location = new Point(12, 46), Size = new Size(196, 150), CheckOnClick = true };
        include.Controls.Add(mainLevels);
        include.Controls.Add(Caption("Secondary factor levels", 220, 20, 190));
        secondLevels = new CheckedListBox { Location = new Point(220, 46), Size = new Size(196, 150), CheckOnClick = true };
        include.Controls.Add(secondLevels);
        var allMain = LinkButtons(include, mainLevels, 12, 200);
        var allSecond = LinkButtons(include, secondLevels, 220, 200);
        include.Controls.Add(Caption("Filters on other columns", 12, 236, 300));
        filterList = new ListBox { Location = new Point(12, 262), Size = new Size(404, 80) };
        include.Controls.Add(filterList);
        var addFilter = new Button { Text = "Add filter\u2026", Location = new Point(12, 350), Size = new Size(110, 28) };
        addFilter.Click += delegate { AddFilter(); };
        include.Controls.Add(addFilter);
        var removeFilter = new Button { Text = "Remove filter", Location = new Point(130, 350), Size = new Size(110, 28) };
        removeFilter.Click += delegate
        {
            if (filterList.SelectedItem != null)
            {
                filters.Remove(filterList.SelectedItem.ToString().Split(':')[0]);
                RefreshFilterList();
            }
        };
        include.Controls.Add(removeFilter);
        Controls.Add(include);

        var plot = Group("Plot", 450, 6, 440, 206);
        plot.Controls.Add(Caption("Title", 12, 24, 100));
        title = new TextBox { Location = new Point(120, 24), Width = 300 };
        plot.Controls.Add(title);
        plot.Controls.Add(Caption("Plot size (inches)", 12, 54, 100));
        plotSize = Number(120, 54, 80, 1, 20, 1);
        plot.Controls.Add(plotSize);
        showLegend = new CheckBox { Text = "Show legend", Location = new Point(240, 54), AutoSize = true };
        plot.Controls.Add(showLegend);
        plot.Controls.Add(Caption("F1 minimum / maximum", 12, 90, 150));
        minF1 = Number(180, 90, 100, 0, 20000, 0);
        maxF1 = Number(300, 90, 100, 0, 20000, 0);
        plot.Controls.Add(minF1);
        plot.Controls.Add(maxF1);
        plot.Controls.Add(Caption("F2 minimum / maximum", 12, 124, 150));
        minF2 = Number(180, 124, 100, 0, 20000, 0);
        maxF2 = Number(300, 124, 100, 0, 20000, 0);
        plot.Controls.Add(minF2);
        plot.Controls.Add(maxF2);
        var unitsNote = Caption("Ranges are in the input units.", 12, 156, 400);
        unitsNote.ForeColor = SystemColors.GrayText;
        plot.Controls.Add(unitsNote);
        Controls.Add(plot);

        var look = Group("Appearance", 450, 218, 440, 150);
        var fontButton = new Button { Text = "Font\u2026", Location = new Point(12, 22), Size = new Size(130, 28) };
        fontButton.Click += delegate { ChooseFont(); };
        fontSummary = new Label { Location = new Point(152, 27), Size = new Size(275, 20), AutoEllipsis = true };
        var unitsButton = new Button { Text = "Output units\u2026", Location = new Point(12, 54), Size = new Size(130, 28) };
        unitsButton.Click += delegate { ChooseOutputUnits(); };
        unitsSummary = new Label { Location = new Point(152, 59), Size = new Size(275, 20), AutoEllipsis = true };
        var folderButton = new Button { Text = "Save folder\u2026", Location = new Point(12, 86), Size = new Size(130, 28) };
        folderButton.Click += delegate { ChooseFolder(); };
        folderSummary = new Label { Location = new Point(152, 91), Size = new Size(275, 20), AutoEllipsis = true };
        colourButton = new Button { Text = "Colour settings\u2026", Location = new Point(12, 118), Size = new Size(130, 28) };
        colourButton.Click += delegate { ChooseColours(); };
        colourSummary = new Label { Location = new Point(152, 123), Size = new Size(275, 20), AutoEllipsis = true };
        look.Controls.AddRange(new Control[] { fontButton, fontSummary, unitsButton, unitsSummary, folderButton, folderSummary, colourButton, colourSummary });
        Controls.Add(look);

        var layers = Group("Layers", 450, 374, 440, 206);
        layers.Controls.Add(Caption("Mark data points using", 12, 24, 170));
        tokenMarking = Drop(190, 24, 230, new[] { "x symbol" }.Concat(table.Columns).Concat(new[] { "Nothing" }));
        layers.Controls.Add(tokenMarking);
        layers.Controls.Add(Caption("Show means", 12, 54, 170));
        showMeans = Drop(190, 54, 230, new[] { "Don't show means", "Without text" }.Concat(table.Columns.Select(c => "With " + c + " text")));
        layers.Controls.Add(showMeans);
        layers.Controls.Add(Caption("Core level", 12, 84, 170));
        coreLevel = Drop(190, 84, 230, new[] { "None" });
        coreLevel.DropDown += delegate { RefreshCoreLevels(); };
        layers.Controls.Add(coreLevel);
        layers.Controls.Add(Caption("Most prominent layer", 12, 114, 170));
        topLayer = Drop(190, 114, 230, new[] { "Mean values", "Data points" });
        layers.Controls.Add(topLayer);
        layers.Controls.Add(Caption("Draw ellipses", 12, 144, 170));
        ellipses = Drop(190, 144, 230, new[] { "No ellipses", "One standard deviation", "Two standard deviations" });
        layers.Controls.Add(ellipses);
        showArrows = new CheckBox { Text = "Show arrows", Location = new Point(190, 174), AutoSize = true };
        layers.Controls.Add(showArrows);
        Controls.Add(layers);

        Controls.Add(Caption("Save name", 10, 592, 70));
        saveName = new TextBox { Location = new Point(84, 592), Width = 150 };
        Controls.Add(saveName);
        saveButton = new Button { Text = "Save image", Location = new Point(244, 589), Size = new Size(96, 28) };
        saveButton.Click += delegate { Request(2); };
        Controls.Add(saveButton);
        drawButton = new Button { Text = "Draw", Name = "Draw", Location = new Point(520, 589), Size = new Size(90, 28) };
        drawButton.Click += delegate { Request(1); };
        Controls.Add(drawButton);
        drawExitButton = new Button { Text = "Draw && Exit", Name = "DrawAndExit", Location = new Point(616, 589), Size = new Size(100, 28) };
        drawExitButton.Click += delegate { Request(3); };
        Controls.Add(drawExitButton);
        var cancel = new Button { Text = "Cancel", Location = new Point(722, 589), Size = new Size(80, 28), DialogResult = DialogResult.Cancel };
        Controls.Add(cancel);
        var help = new Button { Text = "Instructions", Location = new Point(808, 589), Size = new Size(82, 28) };
        help.Click += delegate { ShowInstructions(); };
        Controls.Add(help);
        CancelButton = cancel;
        AcceptButton = drawButton;

        mainFactor.SelectedIndexChanged += delegate { if (!loading) { RefreshLevels(mainLevels, mainFactor.Text, true); RefreshCoreLevels(); } };
        secondFactor.SelectedIndexChanged += delegate { if (!loading) { RefreshLevels(secondLevels, secondFactor.Text, true); RefreshCoreLevels(); } };
        inputUnits.SelectedIndexChanged += delegate { UnitsChanged(); };
        mainLevels.ItemCheck += delegate { if (!refreshing) BeginInvoke((MethodInvoker)RefreshCoreLevels); };
        secondLevels.ItemCheck += delegate { if (!refreshing) BeginInvoke((MethodInvoker)RefreshCoreLevels); };
    }

    private Button[] LinkButtons(GroupBox box, CheckedListBox list, int x, int y)
    {
        var all = new Button { Text = "All", Location = new Point(x, y), Size = new Size(60, 26) };
        all.Click += delegate { SetAll(list, true); };
        var none = new Button { Text = "None", Location = new Point(x + 66, y), Size = new Size(60, 26) };
        none.Click += delegate { SetAll(list, false); };
        box.Controls.Add(all);
        box.Controls.Add(none);
        return new[] { all, none };
    }

    private void SetAll(CheckedListBox list, bool state)
    {
        for (int i = 0; i < list.Items.Count; i++)
            list.SetItemChecked(i, state);
        RefreshCoreLevels();
    }

    private static string Normalise(string name)
    {
        return Regex.Replace(name.ToLowerInvariant(), "[^a-z0-9]", "");
    }

    // F1 or F2 as the formant number: f1, F_1, Formant1, f1_Hz, but not f10.
    private string GuessFormant(int number)
    {
        var pattern = new Regex("^(f|formant)" + number + "([^0-9]|$)");
        string best = null;
        foreach (var name in f1Column.Items.Cast<string>())
        {
            var normal = Normalise(name);
            if (normal == "f" + number || normal == "formant" + number)
                return name;
            if (best == null && pattern.IsMatch(normal))
                best = name;
        }
        return best;
    }

    private void LoadInitialValues()
    {
        Func<ComboBox, string, string, bool> choose = delegate (ComboBox combo, string wanted, string unused)
        {
            int index = combo.Items.IndexOf(wanted);
            if (index < 0)
                return false;
            combo.SelectedIndex = index;
            return true;
        };
        var firstText = table.Columns.FirstOrDefault(c => c.Length > 0 && !table.IsNumeric(table.IndexOf(c)));
        if (!choose(mainFactor, Get("oFactor", ""), null))
            mainFactor.SelectedIndex = Math.Max(0, mainFactor.Items.IndexOf(firstText ?? ""));
        if (mainFactor.SelectedIndex < 0 && mainFactor.Items.Count > 0)
            mainFactor.SelectedIndex = 0;
        string second = Get("iFactor", "");
        if (GetInt("useInnerFactor", 0) == 0 || second == mainFactor.Text || !choose(secondFactor, second, null))
            secondFactor.SelectedIndex = 0;

        var guess1 = GuessFormant(1);
        var guess2 = GuessFormant(2);
        if (!choose(f1Column, Get("f1Col", ""), null) && !choose(f1Column, guess1 ?? "", null) && f1Column.Items.Count > 0)
            f1Column.SelectedIndex = 0;
        if (!choose(f2Column, Get("f2Col", ""), null) && !choose(f2Column, guess2 ?? "", null) && f2Column.Items.Count > 0)
            f2Column.SelectedIndex = Math.Min(1, f2Column.Items.Count - 1);
        // A guess from the column names beats a remembered column left over from another table.
        if (guess1 != null && table.IndexOf(Get("f1Col", "")) < 0) choose(f1Column, guess1, null);
        if (guess2 != null && table.IndexOf(Get("f2Col", "")) < 0) choose(f2Column, guess2, null);

        bool bark = GetInt("inputUnits", 1) == 2;
        string names = Normalise(f1Column.Text + f2Column.Text);
        if (names.Contains("bark"))
            bark = true;
        else if (f1Column.SelectedIndex >= 0 && f2Column.SelectedIndex >= 0 &&
            table.MaximumValue(table.IndexOf(f2Column.Text)) < 30)
            bark = true;
        else if (names.Contains("hz") || (f2Column.SelectedIndex >= 0 && table.MaximumValue(table.IndexOf(f2Column.Text)) >= 30))
            bark = false;
        inputUnits.SelectedIndex = bark ? 1 : 0;
        previousUnits = bark ? 2 : 1;

        title.Text = Get("title", "");
        plotSize.Value = Clamp(GetNumber("plotSize", 5), plotSize);
        showLegend.Checked = GetInt("showLegend", 1) != 0;
        bool remembered = GetInt("inputUnits", 1) == previousUnits;
        decimal[] defaults = bark ? new decimal[] { 1, 10, 4, 16 } : new decimal[] { 150, 1400, 500, 3800 };
        minF1.Value = Clamp(remembered ? GetNumber("minF1", defaults[0]) : defaults[0], minF1);
        maxF1.Value = Clamp(remembered ? GetNumber("maxF1", defaults[1]) : defaults[1], maxF1);
        minF2.Value = Clamp(remembered ? GetNumber("minF2", defaults[2]) : defaults[2], minF2);
        maxF2.Value = Clamp(remembered ? GetNumber("maxF2", defaults[3]) : defaults[3], maxF2);

        tokenMarking.SelectedIndex = Math.Max(0, Math.Min(tokenMarking.Items.Count - 1, GetInt("tokenMarking", 1) - 1));
        showMeans.SelectedIndex = Math.Max(0, Math.Min(showMeans.Items.Count - 1, GetInt("showMeans", 2) - 1));
        topLayer.SelectedIndex = Math.Max(0, Math.Min(1, GetInt("dataPointsOnTop", 1) - 1));
        ellipses.SelectedIndex = Math.Max(0, Math.Min(2, GetInt("ellipsisSDs", 1) - 1));
        showArrows.Checked = GetInt("showArrows", 1) != 0;
        coreLevel.SelectedIndex = 0;

        fontChoice = Math.Max(1, Math.Min(4, GetInt("fontChoice", 1)));
        baseSize = Math.Max(1, Math.Min(6, GetInt("baseSize", 3)));
        outputUnits = Math.Max(1, Math.Min(6, GetInt("outputUnits", 1)));
        saveFolder = Get("saveDir", "");
        saveName.Text = Get("saveName", "F1F2_Plot.png");
        colourMode = 1;
    }

    private static decimal Clamp(decimal value, NumericUpDown box)
    {
        return Math.Max(box.Minimum, Math.Min(box.Maximum, value));
    }

    private void UnitsChanged()
    {
        if (loading)
            return;
        int units = inputUnits.SelectedIndex + 1;
        if (units == previousUnits)
            return;
        previousUnits = units;
        if (units == 2)
        {
            minF1.Value = 1; maxF1.Value = 10; minF2.Value = 4; maxF2.Value = 16;
        }
        else
        {
            minF1.Value = 150; maxF1.Value = 1400; minF2.Value = 500; maxF2.Value = 3800;
        }
        RefreshSummaries();
    }

    private void RefreshLevels(CheckedListBox list, string column, bool allChecked)
    {
        var previous = new HashSet<string>(list.CheckedItems.Cast<string>());
        bool hadItems = list.Items.Count > 0;
        refreshing = true;
        try
        {
            list.Items.Clear();
            int index = column == None ? -1 : table.IndexOf(column);
            list.Enabled = index >= 0;
            if (index < 0)
                return;
            foreach (var level in table.Levels(index))
                list.Items.Add(level, allChecked || !hadItems || previous.Contains(level));
        }
        finally { refreshing = false; }
    }

    private string EffectiveFactor
    {
        get { return secondFactor.Text != None && secondFactor.Text != mainFactor.Text ? secondFactor.Text : mainFactor.Text; }
    }

    private CheckedListBox EffectiveList
    {
        get { return EffectiveFactor == mainFactor.Text ? mainLevels : secondLevels; }
    }

    private void RefreshCoreLevels()
    {
        var selected = coreLevel.Text;
        coreLevel.Items.Clear();
        coreLevel.Items.Add("None");
        foreach (var level in EffectiveList.CheckedItems.Cast<string>())
            coreLevel.Items.Add(level);
        int index = coreLevel.Items.IndexOf(selected);
        coreLevel.SelectedIndex = index < 0 ? 0 : index;
    }

    private void RefreshSummaries()
    {
        fontSummary.Text = FontNames[fontChoice - 1] + ", base size " + FontSizes[baseSize - 1] + " pt";
        bool bark = inputUnits.SelectedIndex == 1;
        unitsSummary.Text = bark ? "Bark (input and output)" : OutputUnitNames[outputUnits - 1];
        folderSummary.Text = saveFolder.Length == 0 ? "Default folder" : saveFolder;
        colourSummary.Text = activeColourMatch ? "Custom colours for this dialog" :
            ColourModes[colourMode - 1].Split('(')[0].Trim() + (addColourScheme ? "; add or change scheme" : "");
    }

    private Form SmallDialog(string text, int width, int height)
    {
        return new Form
        {
            Text = text, ClientSize = new Size(width, height), FormBorderStyle = FormBorderStyle.FixedDialog,
            StartPosition = FormStartPosition.CenterParent, MaximizeBox = false, MinimizeBox = false, ShowInTaskbar = false,
            Font = Font
        };
    }

    private static void OkCancel(Form form, int y)
    {
        var ok = new Button { Text = "OK", Location = new Point(form.ClientSize.Width - 176, y), Size = new Size(80, 28), DialogResult = DialogResult.OK };
        var cancel = new Button { Text = "Cancel", Location = new Point(form.ClientSize.Width - 90, y), Size = new Size(80, 28), DialogResult = DialogResult.Cancel };
        form.Controls.Add(ok);
        form.Controls.Add(cancel);
        form.AcceptButton = ok;
        form.CancelButton = cancel;
    }

    private void ChooseFont()
    {
        using (var form = SmallDialog("Font", 340, 130))
        {
            form.Controls.Add(Caption("Font", 12, 14, 100));
            var font = Drop(130, 14, 190, FontNames);
            font.SelectedIndex = fontChoice - 1;
            form.Controls.Add(font);
            form.Controls.Add(Caption("Base font size (pt)", 12, 46, 115));
            var size = Drop(130, 46, 190, FontSizes);
            size.SelectedIndex = baseSize - 1;
            form.Controls.Add(size);
            OkCancel(form, 88);
            if (form.ShowDialog(this) == DialogResult.OK)
            {
                fontChoice = font.SelectedIndex + 1;
                baseSize = size.SelectedIndex + 1;
                RefreshSummaries();
            }
        }
    }

    private void ChooseOutputUnits()
    {
        if (inputUnits.SelectedIndex == 1)
        {
            MessageBox.Show(this, "With Bark input, the plot is drawn in Bark. Output units can be chosen when the input units are Hertz.", Text, MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }
        using (var form = SmallDialog("Output units", 360, 250))
        {
            form.Controls.Add(Caption("Show the plot axes in:", 12, 8, 330));
            var buttons = new List<RadioButton>();
            for (int i = 0; i < OutputUnitNames.Length; i++)
            {
                var radio = new RadioButton { Text = OutputUnitNames[i], Location = new Point(24, 36 + i * 28), AutoSize = true, Checked = i == outputUnits - 1 };
                buttons.Add(radio);
                form.Controls.Add(radio);
            }
            OkCancel(form, 210);
            if (form.ShowDialog(this) == DialogResult.OK)
            {
                outputUnits = buttons.FindIndex(b => b.Checked) + 1;
                RefreshSummaries();
            }
        }
    }

    private void ChooseFolder()
    {
        using (var dialog = new FolderBrowserDialog())
        {
            dialog.Description = "Choose the folder for saved images.";
            if (saveFolder.Length > 0 && System.IO.Directory.Exists(saveFolder))
                dialog.SelectedPath = saveFolder;
            if (dialog.ShowDialog(this) == DialogResult.OK)
            {
                saveFolder = dialog.SelectedPath;
                RefreshSummaries();
            }
        }
    }

    private void ChooseColours()
    {
        using (var form = SmallDialog("Colour settings", 500, 280))
        {
            form.Controls.Add(Caption("Changes are applied when you press OK:", 12, 8, 470));
            var buttons = new List<RadioButton>();
            for (int i = 0; i < ColourModes.Length; i++)
            {
                var radio = new RadioButton { Text = ColourModes[i], Location = new Point(24, 34 + i * 26), AutoSize = true, Checked = i == colourMode - 1 };
                buttons.Add(radio);
                form.Controls.Add(radio);
            }
            var add = new CheckBox { Text = "Add or change a colour scheme (a Praat window opens)", Location = new Point(24, 200), AutoSize = true, Checked = addColourScheme };
            form.Controls.Add(add);
            buttons[5].CheckedChanged += delegate
            {
                if (buttons[5].Checked) add.Checked = false;
                add.Enabled = !buttons[5].Checked;
            };
            add.Enabled = !buttons[5].Checked;
            OkCancel(form, 240);
            if (form.ShowDialog(this) == DialogResult.OK)
            {
                colourMode = buttons.FindIndex(b => b.Checked) + 1;
                addColourScheme = add.Checked;
                RefreshSummaries();
                Request(4);
            }
        }
    }

    private void AddFilter()
    {
        var used = new HashSet<string>(new[] { mainFactor.Text, secondFactor.Text, f1Column.Text, f2Column.Text });
        var candidates = table.Columns.Where(c => c.Length > 0 && !used.Contains(c) && !filters.ContainsKey(c)).ToArray();
        if (candidates.Length == 0)
        {
            MessageBox.Show(this, "There are no other columns to filter on.", Text, MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }
        using (var form = SmallDialog("Add filter", 380, 380))
        {
            form.Controls.Add(Caption("Column", 12, 12, 80));
            var column = Drop(100, 12, 260, candidates);
            column.SelectedIndex = 0;
            form.Controls.Add(column);
            form.Controls.Add(Caption("Keep rows with these values:", 12, 46, 340));
            var values = new CheckedListBox { Location = new Point(12, 72), Size = new Size(350, 240), CheckOnClick = true };
            form.Controls.Add(values);
            Action fill = delegate
            {
                values.Items.Clear();
                foreach (var level in table.Levels(table.IndexOf(column.Text)))
                    values.Items.Add(level, true);
            };
            column.SelectedIndexChanged += delegate { fill(); };
            fill();
            OkCancel(form, 332);
            if (form.ShowDialog(this) == DialogResult.OK)
            {
                if (values.CheckedItems.Count == 0)
                {
                    MessageBox.Show(this, "Tick at least one value to keep.", Text, MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
                }
                if (values.CheckedItems.Count < values.Items.Count)
                {
                    filters[column.Text] = new HashSet<string>(values.CheckedItems.Cast<string>());
                    RefreshFilterList();
                }
            }
        }
    }

    private void RefreshFilterList()
    {
        filterList.Items.Clear();
        foreach (var pair in filters)
            filterList.Items.Add(pair.Key + ": keeping " + pair.Value.Count + " of " +
                table.Levels(table.IndexOf(pair.Key)).Count + " values");
    }

    private void ShowInstructions()
    {
        MessageBox.Show(this,
            "1. Choose the factors that group your data, and the F1 and F2 columns.\n" +
            "2. Tick the levels to include. Use Add filter to restrict other columns.\n" +
            "3. Set the plot title, size and axis ranges, then the layers to show.\n" +
            "4. Use Font, Output units, Save folder and Colour settings for the look of the plot.\n" +
            "5. Press Draw. The plot appears in the Praat Picture window and this window stays open, " +
            "so you can change settings and draw again.\n" +
            "6. Press Save image to save the plot currently shown in the Picture window as a PNG file. " +
            "Draw & Exit draws the plot and closes this window.",
            "AERoPlot: F1-F2 plot", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }

    private static string Clean(string value)
    {
        return (value ?? "").Replace('\t', ' ').Replace('\r', ' ').Replace('\n', ' ');
    }

    private static string Num(decimal value)
    {
        return value.ToString(CultureInfo.InvariantCulture);
    }

    private string CheckInput(bool coloursOnly)
    {
        if (f1Column.SelectedIndex < 0 || f2Column.SelectedIndex < 0)
            return "Choose a numeric column for F1 and for F2. The table needs at least two numeric columns.";
        if (mainFactor.SelectedIndex < 0)
            return "Choose a main factor.";
        if (f1Column.Text == f2Column.Text)
            return "F1 and F2 need different columns.";
        if (mainLevels.CheckedItems.Count == 0)
            return "Tick at least one level of the main factor.";
        if (secondFactor.Text != None && secondFactor.Text != mainFactor.Text && secondLevels.CheckedItems.Count == 0)
            return "Tick at least one level of the secondary factor.";
        if (!coloursOnly && (minF1.Value >= maxF1.Value || minF2.Value >= maxF2.Value))
            return "Each maximum must be greater than its minimum.";
        if (!coloursOnly && saveName.Text.Trim().Length == 0)
            return "Enter a save name.";
        return null;
    }

    private void Request(int action)
    {
        string problem = action == 2 ? null : CheckInput(action == 4);
        if (problem != null)
        {
            MessageBox.Show(this, problem, Text, MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }
        if ((action == 1 || action == 3) && activeColourMatch && mainFactor.Text != matchedFactor)
        {
            MessageBox.Show(this, "The custom colours were chosen for " + matchedFactor +
                ". Choose colours again for the current main factor before drawing.", Text,
                MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }
        string requestFactor = mainFactor.Text;
        var lines = new List<string>();
        Action<string, string> put = delegate (string key, string value) { lines.Add(key + "\t" + Clean(value)); };
        bool useSecond = secondFactor.Text != None && secondFactor.Text != mainFactor.Text;
        put("oFactor$", mainFactor.Text);
        put("iFactor$", useSecond ? secondFactor.Text : "");
        put("useInnerFactor", useSecond ? "1" : "0");
        put("f1Col$", f1Column.Text);
        put("f2Col$", f2Column.Text);
        put("inputUnits", (inputUnits.SelectedIndex + 1).ToString(CultureInfo.InvariantCulture));
        put("title$", title.Text);
        put("plotSize", Num(plotSize.Value));
        put("minF1", Num(minF1.Value));
        put("maxF1", Num(maxF1.Value));
        put("minF2", Num(minF2.Value));
        put("maxF2", Num(maxF2.Value));
        put("showLegend", showLegend.Checked ? "1" : "0");
        put("fontChoice", fontChoice.ToString(CultureInfo.InvariantCulture));
        put("baseSize", baseSize.ToString(CultureInfo.InvariantCulture));
        put("outputUnits", inputUnits.SelectedIndex == 1 ? "7" : outputUnits.ToString(CultureInfo.InvariantCulture));
        put("tokenMarking", tokenMarking.SelectedIndex.ToString(CultureInfo.InvariantCulture));
        put("showMeans", (showMeans.SelectedIndex - 1).ToString(CultureInfo.InvariantCulture));
        put("ellipsisSDs", ellipses.SelectedIndex.ToString(CultureInfo.InvariantCulture));
        put("showArrows", showArrows.Checked ? "1" : "0");
        put("coreLevelName$", coreLevel.SelectedIndex > 0 ? coreLevel.Text : "");
        put("dataPointsOnTop", topLayer.SelectedIndex.ToString(CultureInfo.InvariantCulture));
        put("saveDir$", saveFolder);
        put("saveName$", saveName.Text.Trim());
        put("sorting", (action == 4 ? colourMode : 1).ToString(CultureInfo.InvariantCulture));
        put("changeAddColSch", action == 4 && addColourScheme ? "1" : "0");
        put("colourSession$", colourSession);
        AddKeep(lines, mainFactor.Text, mainLevels);
        if (useSecond)
            AddKeep(lines, secondFactor.Text, secondLevels);
        foreach (var pair in filters)
            foreach (var level in pair.Value)
                lines.Add("keep\t" + Clean(pair.Key) + "\t" + Clean(level));

        string token = Guid.NewGuid().ToString("N");
        string completion = System.IO.Path.Combine(tempDirectory, "f1f2-complete-" + token + ".txt");
        System.IO.File.WriteAllText(System.IO.Path.Combine(tempDirectory, "f1f2-response-" + token + ".txt"),
            string.Join("\n", lines.ToArray()) + "\n", new UTF8Encoding(false));
        string script = "runScript: \"" + async.CallbackScript + "\", \"" + token + "\", " + async.SoundId + ", " + action + "\n";
        SetBusy(true);
        var worker = new System.Threading.Thread(delegate ()
        {
            string failure = PraatLink.Send(async.PraatProcessId, async.PreferencesDirectory, script);
            bool cancelled = false;
            if (action != 2 && failure == null)
            {
                try
                {
                    int waited = 0;
                    string result = "";
                    while (result != "OK" && result != "CANCELLED" &&
                        PraatLink.IsRunning(async.PraatProcessId) && waited < 600000)
                    {
                        if (System.IO.File.Exists(completion))
                            result = System.IO.File.ReadAllText(completion).Trim();
                        if (result == "OK" || result == "CANCELLED") break;
                        System.Threading.Thread.Sleep(200);
                        waited += 200;
                    }
                    if (result != "OK" && result != "CANCELLED")
                        failure = "The request did not complete. Check Praat for an error.";
                    else
                    {
                        System.IO.File.Delete(completion);
                        cancelled = result == "CANCELLED";
                    }
                    if (IsDisposed)
                    {
                        string path = System.IO.Path.Combine(tempDirectory, "f1f2-colours-" + colourSession + ".txt");
                        if (System.IO.File.Exists(path)) System.IO.File.Delete(path);
                    }
                }
                catch (System.IO.IOException e) { failure = "Could not read the colour settings result: " + e.Message; }
                catch (UnauthorizedAccessException e) { failure = "Could not read the colour settings result: " + e.Message; }
            }
            try
            {
                BeginInvoke((MethodInvoker)delegate
                {
                    SetBusy(false);
                    if (failure != null)
                    {
                        MessageBox.Show(this, failure, Text, MessageBoxButtons.OK, MessageBoxIcon.Information);
                        return;
                    }
                    if (action == 4)
                    {
                        if (!cancelled)
                        {
                            if (colourMode != 1 || addColourScheme)
                            {
                                activeColourMatch = colourMode == 5;
                                matchedFactor = requestFactor;
                            }
                        }
                        colourMode = 1;
                        addColourScheme = false;
                        RefreshSummaries();
                    }
                    if (action == 3)
                    {
                        DialogResult = DialogResult.OK;
                        Close();
                    }
                });
            }
            catch (InvalidOperationException) { }
        });
        worker.IsBackground = true;
        worker.Start();
    }

    private static void AddKeep(List<string> lines, string column, CheckedListBox list)
    {
        if (list.CheckedItems.Count == list.Items.Count)
            return;
        foreach (var level in list.CheckedItems.Cast<string>())
            lines.Add("keep\t" + Clean(column) + "\t" + Clean(level));
    }

    private void SetBusy(bool busy)
    {
        this.busy = busy;
        drawButton.Enabled = !busy;
        drawExitButton.Enabled = !busy;
        saveButton.Enabled = !busy;
        colourButton.Enabled = !busy;
        UseWaitCursor = busy;
    }

    private void StartParentWatch()
    {
        var timer = new Timer { Interval = 1000 };
        timer.Tick += delegate
        {
            if (!PraatLink.IsRunning(async.PraatProcessId))
            {
                timer.Stop();
                DialogResult = DialogResult.Cancel;
                Close();
            }
        };
        timer.Start();
    }
}
