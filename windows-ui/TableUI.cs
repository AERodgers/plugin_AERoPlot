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
            if (args.Length > 0 && args[0] == "PLOT")
                return PlotUI.Run(args);
            if (args.Length > 0 && args[0] == "TABLE")
                return TableUI.Run(args);
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
    // and 13 tab-separated initial values (see TableWindow).
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
            if (parts.Length != 2 || (parts[0] != "I" && parts[0] != "P") || parts[1].Length == 0)
                throw new ArgumentException("The table interface received invalid tiers.");
            tiers.Add(new TableWindow.Tier { Id = id, Name = parts[1], Interval = parts[0] == "I" });
        }
        var initial = args[4].Split('\t');
        if (initial.Length != 13)
            throw new ArgumentException("The table interface received incomplete settings.");
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        using (var window = new TableWindow(args[1], args[2], tiers, initial))
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
        public override string ToString() { return Name; }
    }

    private readonly List<Tier> tiers;
    private readonly TextBox tableName = new TextBox();
    private readonly ComboBox baseTier = new ComboBox();
    private readonly CheckedListBox otherTiers = new CheckedListBox();
    private readonly CheckBox baseTimesOnly = new CheckBox();
    private readonly ComboBox formants = new ComboBox();
    private readonly ComboBox scale = new ComboBox();
    private readonly ComboBox pointTier = new ComboBox();
    private readonly ComboBox durationTier = new ComboBox();
    private readonly NumericUpDown timeStep;
    private readonly NumericUpDown maximumFormant;
    private readonly NumericUpDown numberOfFormants;
    private readonly NumericUpDown windowLength;
    private readonly NumericUpDown preEmphasis;
    private readonly GroupBox vowelGroup = new GroupBox();
    private readonly GroupBox burgGroup = new GroupBox();
    public string Result { get; private set; }

    // Initial values: name, base tier number, other tier numbers (or "-"), base times only (0/1),
    // formants (1-5), point tier number (0 = none), interval tier number (0 = none), scale (1-2),
    // time step, maximum formant, number of formants, window length, pre-emphasis.
    public TableWindow(string sound, string grid, List<Tier> tierList, string[] initial)
    {
        tiers = tierList;
        Text = "AERoPlot - Create Table";
        Name = "TableSettings";
        StartPosition = FormStartPosition.CenterScreen;
        MinimumSize = new Size(620, 420);
        Font = SystemFonts.MessageBoxFont;
        AutoScaleMode = AutoScaleMode.Font;

        var root = new TableLayoutPanel { Dock = DockStyle.Fill, Padding = new Padding(12), ColumnCount = 1, RowCount = 3 };
        root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        root.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
        root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        Controls.Add(root);
        root.Controls.Add(new Label {
            Text = "Sound: " + sound + "    TextGrid: " + grid, AutoSize = true,
            Padding = new Padding(0, 0, 0, 8), MaximumSize = new Size(600, 0)
        }, 0, 0);

        var body = new Panel { Dock = DockStyle.Fill, AutoScroll = true };
        var sections = new FlowLayoutPanel {
            Dock = DockStyle.Top, FlowDirection = FlowDirection.TopDown, WrapContents = false,
            AutoSize = true, AutoSizeMode = AutoSizeMode.GrowAndShrink
        };
        body.Controls.Add(sections);
        root.Controls.Add(body, 0, 1);

        tableName.Width = 560;
        tableName.Text = initial[0];
        tableName.Name = "TableName";
        sections.Controls.Add(Heading("Table name"));
        sections.Controls.Add(tableName);

        sections.Controls.Add(Heading("Base tier (one row per labelled interval or point)"));
        baseTier.DropDownStyle = ComboBoxStyle.DropDownList;
        baseTier.Width = 560;
        baseTier.Name = "BaseTier";
        foreach (var tier in tiers) baseTier.Items.Add(tier);
        baseTier.SelectedIndex = Clamp(Parse(initial[1]), 1, tiers.Count) - 1;
        sections.Controls.Add(baseTier);

        sections.Controls.Add(Heading("Other tiers to include"));
        sections.Controls.Add(Note("Select the tiers that contain information you want to include."));
        otherTiers.CheckOnClick = true;
        otherTiers.Width = 560;
        otherTiers.Height = Math.Min(Math.Max(tiers.Count, 3), 8) * otherTiers.ItemHeight + 6;
        otherTiers.Name = "OtherTiers";
        foreach (var tier in tiers) otherTiers.Items.Add(tier);
        if (initial[2] != "-")
            foreach (var value in initial[2].Split(','))
            {
                int index = Parse(value);
                if (index >= 1 && index <= tiers.Count && index != baseTier.SelectedIndex + 1)
                    otherTiers.SetItemChecked(index - 1, true);
            }
        sections.Controls.Add(otherTiers);
        baseTimesOnly.Text = "Include times for the base tier only";
        baseTimesOnly.AutoSize = true;
        baseTimesOnly.Checked = initial[3] == "1";
        sections.Controls.Add(baseTimesOnly);

        sections.Controls.Add(Heading("Optional formant processing"));
        formants.DropDownStyle = ComboBoxStyle.DropDownList;
        formants.Width = 250;
        formants.Name = "Formants";
        formants.Items.AddRange(new object[] { "None", "F1", "F1 and F2", "F1 - F3", "F1 - F4" });
        formants.SelectedIndex = Clamp(Parse(initial[4]), 1, 5) - 1;
        scale.DropDownStyle = ComboBoxStyle.DropDownList;
        scale.Width = 250;
        scale.Name = "FrequencyScale";
        scale.Items.AddRange(new object[] { "Hertz", "Bark" });
        scale.SelectedIndex = Clamp(Parse(initial[7]), 1, 2) - 1;
        sections.Controls.Add(Pair("Formants to tabulate", formants));
        sections.Controls.Add(Pair("Frequency scale", scale));
        sections.Controls.Add(Note("Formants use the base tier times. If the base tier is an interval tier, each value is the mean over the interval."));

        vowelGroup.Text = "Vowel duration";
        vowelGroup.Width = 580;
        vowelGroup.AutoSize = true;
        var vowelFlow = new FlowLayoutPanel { FlowDirection = FlowDirection.TopDown, WrapContents = false, AutoSize = true, Dock = DockStyle.Fill, Padding = new Padding(6) };
        vowelFlow.Controls.Add(Note("Adds a vowel duration column. This needs a point base tier, a formant selection, and both tiers below."));
        FillTierCombo(pointTier, false, Parse(initial[5]), "PointTier");
        FillTierCombo(durationTier, true, Parse(initial[6]), "DurationTier");
        vowelFlow.Controls.Add(Pair("Point tier for formant measurement times", pointTier));
        vowelFlow.Controls.Add(Pair("Interval tier for vowel duration", durationTier));
        vowelGroup.Controls.Add(vowelFlow);
        sections.Controls.Add(vowelGroup);

        burgGroup.Text = "Formant analysis (To Formant (Burg))";
        burgGroup.Width = 580;
        burgGroup.AutoSize = true;
        var burgFlow = new FlowLayoutPanel { FlowDirection = FlowDirection.TopDown, WrapContents = false, AutoSize = true, Dock = DockStyle.Fill, Padding = new Padding(6) };
        timeStep = Numeric(initial[8], 0, 10, 4, 0.005m, "TimeStep");
        maximumFormant = Numeric(initial[9], 1000, 20000, 0, 100, "MaximumFormant");
        numberOfFormants = Numeric(initial[10], 1, 20, 1, 0.5m, "NumberOfFormants");
        windowLength = Numeric(initial[11], 0.001m, 2, 4, 0.005m, "WindowLength");
        preEmphasis = Numeric(initial[12], 1, 20000, 0, 10, "PreEmphasis");
        burgFlow.Controls.Add(Pair("Time step (s; 0 = automatic)", timeStep));
        burgFlow.Controls.Add(Pair("Maximum formant (Hz)", maximumFormant));
        burgFlow.Controls.Add(Pair("Number of formants (for estimation)", numberOfFormants));
        burgFlow.Controls.Add(Pair("Window length (s)", windowLength));
        burgFlow.Controls.Add(Pair("Pre-emphasis from (Hz)", preEmphasis));
        burgGroup.Controls.Add(burgFlow);
        sections.Controls.Add(burgGroup);
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
        int maximumHeight = Screen.FromPoint(Cursor.Position).WorkingArea.Height - 60;
        ClientSize = new Size(640, Math.Max(420, Math.Min(sections.PreferredSize.Height + 110, maximumHeight)));
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
        return new Label { Text = text, AutoSize = true, MaximumSize = new Size(560, 0), Padding = new Padding(0, 2, 0, 2) };
    }

    private static Control Pair(string label, Control control)
    {
        var row = new TableLayoutPanel { ColumnCount = 2, RowCount = 1, AutoSize = true, Margin = new Padding(0, 2, 0, 2) };
        row.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 270));
        row.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        row.Controls.Add(new Label { Text = label, AutoSize = true, Anchor = AnchorStyles.Left, MaximumSize = new Size(265, 0) }, 0, 0);
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

    private void FillTierCombo(ComboBox box, bool interval, int selectedId, string name)
    {
        box.DropDownStyle = ComboBoxStyle.DropDownList;
        box.Width = 250;
        box.Name = name;
        box.Items.Add(new Tier { Id = 0, Name = "(none)" });
        box.SelectedIndex = 0;
        foreach (var tier in tiers.Where(t => t.Interval == interval))
        {
            int index = box.Items.Add(tier);
            if (tier.Id == selectedId)
                box.SelectedIndex = index;
        }
    }

    private void UpdateControls()
    {
        bool tabulate = formants.SelectedIndex > 0;
        scale.Enabled = tabulate;
        vowelGroup.Enabled = tabulate;
        burgGroup.Enabled = tabulate;
    }

    private void ShowInstructions()
    {
        MessageBox.Show(this,
            "Choose the base tier: the table has one row for each labelled interval or point on it. " +
            "Tick the other tiers whose labels you want as extra columns; every base-tier item must lie inside them." + Environment.NewLine + Environment.NewLine +
            "Formants are estimated at the base tier times with To Formant (Burg). The number of formants for estimation always refers to the maximum formant ceiling, " +
            "even when fewer formants are tabulated." + Environment.NewLine + Environment.NewLine +
            "Vowel duration needs a point base tier, a formant selection, a point tier and an interval tier.",
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
        if (otherTiers.GetItemChecked(baseTier.SelectedIndex))
        {
            MessageBox.Show(this, "The base tier cannot also be selected as an additional tier.", Text, MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }
        int formantCount = formants.SelectedIndex + 1;
        int point = formantCount > 1 ? ((Tier)pointTier.SelectedItem).Id : 0;
        int duration = formantCount > 1 ? ((Tier)durationTier.SelectedItem).Id : 0;
        if ((point == 0) != (duration == 0))
        {
            MessageBox.Show(this, "Vowel duration needs both a point tier and an interval tier. Choose both, or set both to (none).", Text, MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }
        if (point != 0 && tiers[baseTier.SelectedIndex].Interval)
        {
            MessageBox.Show(this, "Vowel duration needs a point tier as the base tier.", Text, MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }
        var indexes = new List<string>();
        foreach (int index in otherTiers.CheckedIndices)
            indexes.Add((index + 1).ToString(CultureInfo.InvariantCulture));
        var fields = new List<string> {
            "OK", name, (baseTier.SelectedIndex + 1).ToString(CultureInfo.InvariantCulture),
            indexes.Count == 0 ? "-" : String.Join(",", indexes.ToArray()),
            baseTimesOnly.Checked ? "1" : "0", formantCount.ToString(CultureInfo.InvariantCulture),
            point.ToString(CultureInfo.InvariantCulture), duration.ToString(CultureInfo.InvariantCulture),
            (scale.SelectedIndex + 1).ToString(CultureInfo.InvariantCulture),
            Format(timeStep.Value), Format(maximumFormant.Value), Format(numberOfFormants.Value),
            Format(windowLength.Value), Format(preEmphasis.Value)
        };
        Result = String.Join(" ", fields.ToArray()) + "\n";
        DialogResult = DialogResult.OK;
        Close();
    }
}
