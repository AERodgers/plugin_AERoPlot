using System;
using System.Collections.Generic;
using System.Drawing;
using System.Globalization;
using System.Linq;
using System.Windows.Forms;

internal static class Program
{
    [STAThread]
    private static int Main(string[] args)
    {
        try
        {
            if (args.Length > 0 && args[0] == "WARMUP")
            {
                // Started in the background when Praat opens, so that Windows has
                // already checked this program and loaded Windows Forms later.
                using (new Form()) { }
                return 0;
            }
            if (args.Length > 0 && args[0] == "PLOT")
                return PlotUI.Run(args);
            if (args.Length > 0 && args[0] == "TABLE")
                return TableUI.Run(args);
            if (args.Length > 0 && args[0] == "TABLEPLOT")
                return TablePlotUI.Run(args);
            if (args.Length > 0 && args[0] == "TABLELAD")
                return TablePlotUI.Run(args);
            if (args.Length > 0 && args[0] == "TABLEFOT")
                return TablePlotUI.Run(args);
            throw new ArgumentException("The requested interface is not supported.");
        }
        catch (Exception error)
        {
            MessageBox.Show(error.Message, "AERoPlot Windows interface", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }
}

internal static class TableUI
{
    // Arguments: TABLE, Sound name, TextGrid name, tiers (one "I" or "P", a tab, then the name per line),
    // and 12 legacy or 21 current tab-separated initial values (see TableWindow).
    public static int Run(string[] args)
    {
        if (args.Length != 5)
            throw new ArgumentException("The table interface received invalid input.");
        var tiers = new List<TableWindow.Tier>();
        int id = 0;
        foreach (var line in args[3].Split('\n'))
        {
            var parts = line.Split('\t');
            id++;
            if (parts.Length != 3 || (parts[0] != "I" && parts[0] != "P") || parts[1].Length == 0)
                throw new ArgumentException("The table interface received invalid tiers.");
            tiers.Add(new TableWindow.Tier { Id = id, Name = parts[1], Interval = parts[0] == "I", Nested = parts[2] });
        }
        var initial = args[4].Split('\t');
        if (initial.Length != 12 && initial.Length != 21)
            throw new ArgumentException("The table interface received incomplete settings.");
        bool legacyProtocol = initial.Length == 12;
        if (initial.Length == 12)
            initial = initial.Concat(new[] { "0", "0", "0", "0", "0", "1", "1", "1", "100" }).ToArray();
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        using (var window = new TableWindow(args[1], args[2], tiers, initial, legacyProtocol))
        {
            if (window.ShowDialog() == DialogResult.OK)
                Console.Write(window.Result);
            else
                Console.Write("CANCEL\n");
        }
        return 0;
    }
}

internal sealed class TableWindow : Form
{
    internal sealed class Tier
    {
        public int Id;
        public string Name;
        public bool Interval;
        // One 0/1 per possible base tier: can this tier fill a column for that base?
        public string Nested = "";
        public override string ToString() { return Name; }
    }

    private const int ColumnWidth = 400;

    private readonly List<Tier> tiers;
    private readonly bool legacyProtocol;
    private readonly HashSet<int> checkedIds = new HashSet<int>();
    private bool refreshing;
    private bool refreshingOptionalTiers;
    private readonly TextBox tableName = new TextBox();
    private readonly ComboBox baseTier = new ComboBox();
    private readonly CheckedListBox otherTiers = new CheckedListBox();
    private readonly CheckBox baseTimesOnly = new CheckBox();
    private readonly ComboBox formants = new ComboBox();
    private readonly ComboBox scale = new ComboBox();
    private readonly ComboBox[] durationTiers = { new ComboBox(), new ComboBox(), new ComboBox() };
    private readonly ComboBox[] intensityTiers = { new ComboBox(), new ComboBox(), new ComboBox() };
    private readonly ComboBox[] intensityMethods = { new ComboBox(), new ComboBox(), new ComboBox() };
    private readonly Control[] durationRows = new Control[3];
    private readonly Control[] intensityRows = new Control[3];
    private readonly Control[] intensityMethodRows = new Control[3];
    private readonly NumericUpDown intensityPitch;
    private readonly NumericUpDown timeStep;
    private readonly NumericUpDown maximumFormant;
    private readonly NumericUpDown numberOfFormants;
    private readonly NumericUpDown windowLength;
    private readonly NumericUpDown preEmphasis;
    private readonly Control scaleRow;
    private readonly Control burgPanel;
    public string Result { get; private set; }

    // Initial values: the 12 legacy fields followed by duration tiers 2-3, intensity tiers 1-3,
    // intensity methods 1-3, and intensity pitch (Hz).
    public TableWindow(string sound, string grid, List<Tier> tierList, string[] initial, bool legacy)
    {
        tiers = tierList;
        legacyProtocol = legacy;
        Text = "AERoPlot - Create Table";
        Name = "TableSettings";
        StartPosition = FormStartPosition.CenterScreen;
        MinimumSize = new Size(480, 360);
        Font = SystemFonts.MessageBoxFont;
        AutoScaleMode = AutoScaleMode.Font;

        var root = new TableLayoutPanel { Dock = DockStyle.Fill, Padding = new Padding(12), ColumnCount = 1, RowCount = 3 };
        root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        root.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
        root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        Controls.Add(root);
        root.Controls.Add(new Label {
            Text = "Sound: " + sound + "    TextGrid: " + grid, AutoSize = true,
            Padding = new Padding(0, 0, 0, 8), MaximumSize = new Size(2 * ColumnWidth, 0)
        }, 0, 0);

        // Two columns keep the dialog short; the body scrolls only on very small screens.
        var body = new Panel { Dock = DockStyle.Fill, AutoScroll = true };
        var columns = new TableLayoutPanel { Dock = DockStyle.Top, ColumnCount = 2, AutoSize = true, AutoSizeMode = AutoSizeMode.GrowAndShrink };
        columns.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, ColumnWidth + 20));
        columns.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, ColumnWidth + 20));
        var left = Column();
        var right = Column();
        columns.Controls.Add(left, 0, 0);
        columns.Controls.Add(right, 1, 0);
        body.Controls.Add(columns);
        root.Controls.Add(body, 0, 1);

        tableName.Width = ColumnWidth;
        tableName.Text = initial[0];
        tableName.Name = "TableName";
        left.Controls.Add(Heading("Table name"));
        left.Controls.Add(tableName);

        left.Controls.Add(Heading("Base tier (one row per interval or point)"));
        baseTier.DropDownStyle = ComboBoxStyle.DropDownList;
        baseTier.Width = ColumnWidth;
        baseTier.Name = "BaseTier";
        foreach (var tier in tiers) baseTier.Items.Add(tier);
        baseTier.SelectedIndex = Clamp(Parse(initial[1]), 1, tiers.Count) - 1;
        left.Controls.Add(baseTier);

        left.Controls.Add(Heading("Other tiers to include"));
        otherTiers.CheckOnClick = true;
        otherTiers.Width = ColumnWidth;
        otherTiers.Height = Math.Min(Math.Max(tiers.Count, 3), 8) * otherTiers.ItemHeight + 6;
        otherTiers.Name = "OtherTiers";
        if (initial[2] != "-")
            foreach (var value in initial[2].Split(','))
            {
                int index = Parse(value);
                if (index >= 1 && index <= tiers.Count)
                    checkedIds.Add(index);
            }
        otherTiers.ItemCheck += OtherTierChecked;
        baseTier.SelectedIndexChanged += delegate { RefreshOtherTiers(); };
        RefreshOtherTiers();
        left.Controls.Add(otherTiers);
        baseTimesOnly.Text = "Include times for the base tier only";
        baseTimesOnly.AutoSize = true;
        baseTimesOnly.Checked = initial[3] == "1";
        left.Controls.Add(baseTimesOnly);

        left.Controls.Add(Heading("Duration (optional)"));
        left.Controls.Add(Note("Adds one [tier]_dur column (seconds) for each selected interval tier."));
        for (int i = 0; i < durationTiers.Length; i++)
        {
            FillTierCombo(durationTiers[i], true, i == 0 ? Parse(initial[5]) : Parse(initial[11 + i]));
            durationTiers[i].Name = "DurationTier" + (i + 1).ToString(CultureInfo.InvariantCulture);
            durationRows[i] = Pair("Duration tier " + (i + 1).ToString(CultureInfo.InvariantCulture), durationTiers[i], 145);
            left.Controls.Add(durationRows[i]);
            durationTiers[i].SelectedIndexChanged += delegate { UpdateOptionalTierRows(); };
        }

        left.Controls.Add(Heading("Intensity (optional)"));
        left.Controls.Add(Note("Intensity is in dB, rounded to 1 decimal. Absolute sound pressure levels require a calibrated recording. Interval tiers use the chosen statistic; point tiers use point intensity. Pitch floor is in Hz."));
        for (int i = 0; i < intensityTiers.Length; i++)
        {
            FillTierCombo(intensityTiers[i], false, Parse(initial[14 + i]));
            intensityTiers[i].Name = "IntensityTier" + (i + 1).ToString(CultureInfo.InvariantCulture);
            intensityMethods[i].DropDownStyle = ComboBoxStyle.DropDownList;
            intensityMethods[i].Width = 255;
            intensityMethods[i].Name = "IntensityMethod" + (i + 1).ToString(CultureInfo.InvariantCulture);
            intensityMethods[i].Items.AddRange(new object[] { "Mean", "Midpoint", "Minimum", "Maximum" });
            intensityMethods[i].SelectedIndex = Clamp(Parse(initial[17 + i]), 1, 4) - 1;
            intensityRows[i] = Pair("Intensity tier " + (i + 1).ToString(CultureInfo.InvariantCulture), intensityTiers[i], 145);
            intensityMethodRows[i] = Pair("Interval statistic", intensityMethods[i], 145);
            left.Controls.Add(intensityRows[i]);
            left.Controls.Add(intensityMethodRows[i]);
            intensityTiers[i].SelectedIndexChanged += delegate { UpdateOptionalTierRows(); };
        }
        intensityPitch = Numeric(initial[20], 0.001m, 20000, 3, 1, "IntensityPitch");
        left.Controls.Add(Pair("Intensity pitch floor (Hz)", intensityPitch, 145));

        right.Controls.Add(Heading("Formant processing (optional)"));
        formants.DropDownStyle = ComboBoxStyle.DropDownList;
        formants.Width = 180;
        formants.Name = "Formants";
        formants.Items.AddRange(new object[] { "None", "F1", "F1 and F2", "F1 - F3", "F1 - F4" });
        formants.SelectedIndex = Clamp(Parse(initial[4]), 1, 5) - 1;
        scale.DropDownStyle = ComboBoxStyle.DropDownList;
        scale.Width = 180;
        scale.Name = "FrequencyScale";
        scale.Items.AddRange(new object[] { "Hertz", "Bark" });
        scale.SelectedIndex = Clamp(Parse(initial[6]), 1, 2) - 1;
        right.Controls.Add(Pair("Formants to tabulate", formants, 200));
        scaleRow = Pair("Frequency scale", scale, 200);
        right.Controls.Add(scaleRow);

        var burg = Column();
        burg.Margin = new Padding(0);
        burg.Controls.Add(Note("Measured at each base tier point, or averaged across each base tier interval."));
        burg.Controls.Add(Heading("To Formant (Burg) settings"));
        timeStep = Numeric(initial[7], 0, 10, 4, 0.005m, "TimeStep");
        maximumFormant = Numeric(initial[8], 1000, 20000, 0, 100, "MaximumFormant");
        numberOfFormants = Numeric(initial[9], 1, 20, 1, 0.5m, "NumberOfFormants");
        windowLength = Numeric(initial[10], 0.001m, 2, 4, 0.005m, "WindowLength");
        preEmphasis = Numeric(initial[11], 1, 20000, 0, 10, "PreEmphasis");
        burg.Controls.Add(Pair("Time step (s; 0 = automatic)", timeStep, 250));
        burg.Controls.Add(Pair("Maximum formant (Hz)", maximumFormant, 250));
        burg.Controls.Add(Pair("Number of formants", numberOfFormants, 250));
        burg.Controls.Add(Pair("Window length (s)", windowLength, 250));
        burg.Controls.Add(Pair("Pre-emphasis from (Hz)", preEmphasis, 250));
        burgPanel = burg;
        right.Controls.Add(burgPanel);
        formants.SelectedIndexChanged += delegate { UpdateControls(); };

        var buttons = new FlowLayoutPanel { Dock = DockStyle.Fill, AutoSize = true, FlowDirection = FlowDirection.RightToLeft };
        var create = new Button { Text = "Create Table", AutoSize = true, Name = "Create" };
        var cancel = new Button { Text = "Cancel", AutoSize = true, DialogResult = DialogResult.Cancel, Name = "Cancel" };
        var help = new Button { Text = "Instructions", AutoSize = true, Name = "Instructions" };
        create.Click += CreateClicked;
        help.Click += delegate { ShowInstructions(); };
        buttons.Controls.Add(create);
        buttons.Controls.Add(cancel);
        buttons.Controls.Add(help);
        root.Controls.Add(buttons, 0, 2);
        AcceptButton = create;
        CancelButton = cancel;

        UpdateControls();
        UpdateOptionalTierRows();
        int maximumHeight = Screen.FromPoint(Cursor.Position).WorkingArea.Height - 60;
        int height = Math.Max(left.PreferredSize.Height, right.PreferredSize.Height) + 110;
        ClientSize = new Size(2 * (ColumnWidth + 20) + 50, Math.Max(360, Math.Min(height, maximumHeight)));
    }

    private static FlowLayoutPanel Column()
    {
        return new FlowLayoutPanel {
            FlowDirection = FlowDirection.TopDown, WrapContents = false, AutoSize = true,
            AutoSizeMode = AutoSizeMode.GrowAndShrink, Margin = new Padding(0, 0, 20, 0)
        };
    }

    private static int Parse(string value)
    {
        int result;
        return int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out result) ? result : 0;
    }

    private static int Clamp(int value, int low, int high)
    {
        return Math.Max(low, Math.Min(high, value));
    }

    private static string Format(decimal value)
    {
        return value.ToString("0.######", CultureInfo.InvariantCulture);
    }

    private static Label Heading(string text)
    {
        return new Label { Text = text, AutoSize = true, Padding = new Padding(0, 8, 0, 2), Font = new Font(SystemFonts.MessageBoxFont, FontStyle.Bold) };
    }

    private static Label Note(string text)
    {
        return new Label { Text = text, AutoSize = true, MaximumSize = new Size(ColumnWidth, 0), Padding = new Padding(0, 2, 0, 2) };
    }

    private static Control Pair(string label, Control control, int labelWidth)
    {
        var row = new TableLayoutPanel { ColumnCount = 2, RowCount = 1, AutoSize = true, Margin = new Padding(0, 2, 0, 2) };
        row.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, labelWidth));
        row.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        row.Controls.Add(new Label { Text = label, AutoSize = true, Anchor = AnchorStyles.Left, MaximumSize = new Size(labelWidth - 5, 0) }, 0, 0);
        control.Anchor = AnchorStyles.Left;
        row.Controls.Add(control, 1, 0);
        return row;
    }

    private NumericUpDown Numeric(string value, decimal minimum, decimal maximum, int places, decimal increment, string name)
    {
        decimal parsed;
        if (!decimal.TryParse(value, NumberStyles.Float, CultureInfo.InvariantCulture, out parsed))
            parsed = minimum;
        return new NumericUpDown {
            Minimum = minimum, Maximum = maximum, DecimalPlaces = places, Increment = increment,
            Value = Math.Max(minimum, Math.Min(maximum, parsed)), Width = 120, Name = name
        };
    }

    private void FillTierCombo(ComboBox combo, bool intervalsOnly, int selectedId)
    {
        combo.DropDownStyle = ComboBoxStyle.DropDownList;
        combo.Width = 255;
        combo.Items.Add(new Tier { Id = 0, Name = "(none)" });
        combo.SelectedIndex = 0;
        foreach (var tier in tiers.Where(t => !intervalsOnly || t.Interval))
        {
            int index = combo.Items.Add(tier);
            if (tier.Id == selectedId)
                combo.SelectedIndex = index;
        }
    }

    private static int SelectedTierId(ComboBox combo)
    {
        return combo.SelectedItem == null ? 0 : ((Tier)combo.SelectedItem).Id;
    }

    private void UpdateOptionalTierRows()
    {
        if (refreshingOptionalTiers)
            return;
        refreshingOptionalTiers = true;
        for (int i = 1; i < durationRows.Length; i++)
        {
            bool precedingDurationSelected = SelectedTierId(durationTiers[i - 1]) != 0;
            durationRows[i].Visible = precedingDurationSelected;
            if (!precedingDurationSelected)
                durationTiers[i].SelectedIndex = 0;
        }
        for (int i = 1; i < intensityRows.Length; i++)
        {
            bool precedingIntensitySelected = SelectedTierId(intensityTiers[i - 1]) != 0;
            intensityRows[i].Visible = precedingIntensitySelected;
            if (!precedingIntensitySelected)
                intensityTiers[i].SelectedIndex = 0;
        }
        for (int i = 0; i < intensityMethodRows.Length; i++)
        {
            int id = SelectedTierId(intensityTiers[i]);
            intensityMethodRows[i].Visible = id != 0;
            intensityMethods[i].Enabled = id != 0 && tiers[id - 1].Interval;
        }
        refreshingOptionalTiers = false;
    }

    // Tiers that sit inside the base tier would only give empty columns, so they are not offered.
    private void RefreshOtherTiers()
    {
        int baseId = ((Tier)baseTier.SelectedItem).Id;
        refreshing = true;
        otherTiers.Items.Clear();
        foreach (var tier in tiers)
        {
            if (tier.Id == baseId || tier.Nested.Length < baseId || tier.Nested[baseId - 1] != '1')
                continue;
            otherTiers.Items.Add(tier, checkedIds.Contains(tier.Id));
        }
        refreshing = false;
    }

    private void OtherTierChecked(object sender, ItemCheckEventArgs e)
    {
        if (refreshing)
            return;
        int id = ((Tier)otherTiers.Items[e.Index]).Id;
        if (e.NewValue == CheckState.Checked)
            checkedIds.Add(id);
        else
            checkedIds.Remove(id);
    }

    private void UpdateControls()
    {
        bool tabulate = formants.SelectedIndex > 0;
        scaleRow.Visible = tabulate;
        burgPanel.Visible = tabulate;
    }

    private void ShowInstructions()
    {
        MessageBox.Show(this,
            "Choose the base tier: the table has one row for each interval or point on it. " +
            "Tick the other tiers whose labels you want as extra columns; every base-tier item must lie inside them. Tiers that sit inside the base tier would only give empty columns, so they are not listed. " +
            "For one row per point inside a longer segment, use the finest point tier as the base tier." + Environment.NewLine + Environment.NewLine +
            "Each selected duration tier adds a [tier]_dur column (seconds) with the length of the interval of that tier that contains each row. Additional tier slots appear after choosing the preceding tier." + Environment.NewLine + Environment.NewLine +
            "Intensity adds a column for each selected tier, in dB relative to 20 micropascals and rounded to 1 decimal. Absolute sound pressure levels require a calibrated recording. Interval tiers use the selected mean, midpoint, minimum, or maximum statistic; point tiers always use intensity at the point. The pitch floor is shared by all intensity measurements." + Environment.NewLine + Environment.NewLine +
            "Formants are measured with To Formant (Burg). A point base tier gives the value at each point; an interval base tier gives the mean of the defined values across the interval. " +
            "The number of formants for estimation always refers to the maximum formant ceiling, even when fewer formants are tabulated.",
            "Create Table - instructions", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }

    private void CreateClicked(object sender, EventArgs e)
    {
        string name = tableName.Text.Trim();
        if (name.Length == 0 || !System.Text.RegularExpressions.Regex.IsMatch(name, @"^[A-Za-z][A-Za-z0-9_]*$"))
        {
            MessageBox.Show(this, "Use a table name starting with a letter, followed by letters, numbers or underscores.", Text, MessageBoxButtons.OK, MessageBoxIcon.Information);
            tableName.Focus();
            return;
        }
        int formantCount = formants.SelectedIndex + 1;
        int[] durationIds = durationTiers.Select(SelectedTierId).ToArray();
        int[] intensityIds = intensityTiers.Select(SelectedTierId).ToArray();
        var indexes = new List<string>();
        foreach (Tier tier in otherTiers.CheckedItems)
            indexes.Add(tier.Id.ToString(CultureInfo.InvariantCulture));
        var fields = new List<string> {
            "OK", name, (baseTier.SelectedIndex + 1).ToString(CultureInfo.InvariantCulture),
            indexes.Count == 0 ? "-" : String.Join(",", indexes.ToArray()),
            baseTimesOnly.Checked ? "1" : "0", formantCount.ToString(CultureInfo.InvariantCulture),
            durationIds[0].ToString(CultureInfo.InvariantCulture),
            (scale.SelectedIndex + 1).ToString(CultureInfo.InvariantCulture),
            Format(timeStep.Value), Format(maximumFormant.Value), Format(numberOfFormants.Value),
            Format(windowLength.Value), Format(preEmphasis.Value),
            durationIds[1].ToString(CultureInfo.InvariantCulture), durationIds[2].ToString(CultureInfo.InvariantCulture),
            intensityIds[0].ToString(CultureInfo.InvariantCulture), intensityIds[1].ToString(CultureInfo.InvariantCulture),
            intensityIds[2].ToString(CultureInfo.InvariantCulture),
            (intensityMethods[0].SelectedIndex + 1).ToString(CultureInfo.InvariantCulture),
            (intensityMethods[1].SelectedIndex + 1).ToString(CultureInfo.InvariantCulture),
            (intensityMethods[2].SelectedIndex + 1).ToString(CultureInfo.InvariantCulture),
            Format(intensityPitch.Value)
        };
        if (legacyProtocol)
            fields.RemoveRange(13, fields.Count - 13);
        Result = String.Join(" ", fields.ToArray()) + "\n";
        DialogResult = DialogResult.OK;
        Close();
    }
}
