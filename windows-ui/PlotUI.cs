using System;
using System.Collections.Generic;
using System.Drawing;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Windows.Forms;

internal static class PlotUI
{
    private const string EmptyTitle = "__AEROPLOT_EMPTY_TITLE__";

    public static int Run(string[] args)
    {
        try
        {
            if (args.Length != 9)
                throw new ArgumentException("The plot interface received invalid input.");

            var settings = args[7].Split('\t');
            if (settings.Length != 16)
                throw new ArgumentException("The plot interface received incomplete settings.");

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            using (var window = new PlotWindow(args[1], args[2], args[3], args[4], args[5], args[6], args[8], settings))
            {
                if (window.ShowDialog() == DialogResult.OK)
                    Console.Write(window.Result);
                else
                    Console.Write("CANCEL\n");
            }
            return 0;
        }
        catch (Exception error)
        {
            MessageBox.Show(error.Message, "AERoPlot plot UI prototype", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }

    internal static string EmptyTitleValue
    {
        get { return EmptyTitle; }
    }
}

internal sealed class PlotWindow : Form
{
    private sealed class TierChoice
    {
        public readonly int Id;
        public readonly string Name;

        public TierChoice(int id, string name)
        {
            Id = id;
            Name = name;
        }

        public override string ToString()
        {
            return Name;
        }
    }

    private readonly bool spectrogramOnly;
    private readonly TextBox title = new TextBox();
    private readonly NumericUpDown smoothing;
    private readonly CheckBox paintSpectrogram;
    private readonly CheckBox drawWaveform;
    private readonly NumericUpDown windowWidth;
    private readonly NumericUpDown minimumF0;
    private readonly NumericUpDown maximumF0;
    private readonly NumericUpDown minimumDb;
    private readonly NumericUpDown maximumDb;
    private readonly ComboBox plotType;
    private readonly ComboBox f0Scale;
    private readonly ComboBox secondaryParameter;
    private readonly ComboBox font;
    private readonly ComboBox cropTier;
    private readonly ComboBox displayTier;
    private readonly ComboBox textGridFont;
    private readonly CheckBox showBoundaries;
    private readonly string initialTitle;
    private readonly string resultDirectory;
    public string Result { get; private set; }

    public PlotWindow(string mode, string soundName, string gridName, string tierNames, string intervalTierIds, string titleValue, string resultPath, string[] settings)
    {
        if (mode != "PitchPlus" && mode != "Spectrogram")
            throw new ArgumentException("The requested plot mode is not supported.");
        if (!System.IO.Directory.Exists(resultPath))
            throw new ArgumentException("The plot UI's temporary result folder does not exist.");
        spectrogramOnly = mode == "Spectrogram";
        resultDirectory = resultPath;
        initialTitle = titleValue == PlotUI.EmptyTitleValue ? "" : titleValue;

        Text = "AERoPlot - " + mode + " (Windows UI prototype)";
        Name = "PlotSettings";
        StartPosition = FormStartPosition.CenterScreen;
        MinimumSize = new Size(620, 380);
        Font = SystemFonts.MessageBoxFont;
        AutoScaleMode = AutoScaleMode.Font;

        var root = new TableLayoutPanel {
            Dock = DockStyle.Fill, Padding = new Padding(12), ColumnCount = 1, RowCount = 3
        };
        root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        root.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
        root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        Controls.Add(root);
        root.Controls.Add(new Label {
            Text = "Sound: " + soundName + (gridName == "-" ? "" : "    TextGrid: " + gridName),
            AutoSize = true, Padding = new Padding(0, 0, 0, 8), MaximumSize = new Size(600, 0)
        }, 0, 0);

        var body = new Panel {
            Dock = DockStyle.Fill, AutoScroll = true
        };
        var sections = new FlowLayoutPanel {
            Dock = DockStyle.Top, FlowDirection = FlowDirection.TopDown, WrapContents = false,
            AutoSize = false, Width = 620
        };
        body.Controls.Add(sections);
        root.Controls.Add(body, 0, 1);

        smoothing = Number(settings[0], 0, 10000, 0);
        paintSpectrogram = new CheckBox { Text = "Paint spectrogram", AutoSize = true, Checked = Flag(settings[1]) };
        drawWaveform = new CheckBox { Text = "Draw sound waveform", AutoSize = true, Checked = Flag(settings[2]) };
        windowWidth = Number(settings[3], 0.01m, 100, 2);
        minimumF0 = Number(settings[4], 0, 100000, 0);
        maximumF0 = Number(settings[5], 0, 100000, 0);
        minimumDb = Number(settings[6], -10000, 10000, 1);
        maximumDb = Number(settings[7], -10000, 10000, 1);
        plotType = Choice(new[] {
            "F0 + secondary parameter", "F0 only", "Intensity only", "Background only"
        }, Index(settings[8], 1, 4));
        f0Scale = Choice(new[] { "Hertz", "Semitones re 1 Hz" }, Index(settings[9], 1, 2));
        secondaryParameter = Choice(new[] {
            "Cepstral Peak Prominence",
            "Residual of intensity (linear regression)",
            "H1-H2 of differentiated glottal pulse (LPC-IF)",
            "Harmonicity (Praat function)"
        }, Index(settings[10], 1, 4));
        font = Choice(new[] { "Times", "Helvetica", "Palatino", "Courier" }, Index(settings[11], 1, 4));
        showBoundaries = new CheckBox {
            Text = "Show boundaries", AccessibleName = "Show TextGrid boundaries",
            AutoSize = true, Checked = Flag(settings[15])
        };

        var displaySection = Section("Display");
        title.Text = initialTitle;
        title.Dock = DockStyle.Fill;
        AddRow(displaySection, "Image title", title);
        if (!spectrogramOnly)
        {
            AddChecksRow(displaySection, paintSpectrogram, drawWaveform);
            AddRow(displaySection, "F0-only smoothing", smoothing);
        }
        else
            AddChecksRow(displaySection, drawWaveform, null);
        AddPair(displaySection, "Window width (inches)", windowWidth, "Font", font);
        sections.Controls.Add(displaySection);

        if (!spectrogramOnly)
        {
            var pitchSection = Section("Pitch and contour");
            AddPair(pitchSection, "Plot type", plotType, "F0 scale", f0Scale);
            AddRow(pitchSection, "Secondary parameter", secondaryParameter);
            AddPair(pitchSection, "Minimum F0 (Hz)", minimumF0, "Maximum F0 (Hz)", maximumF0);
            AddPair(pitchSection, "Minimum intensity (dB)", minimumDb, "Maximum intensity (dB)", maximumDb);
            sections.Controls.Add(pitchSection);
            plotType.SelectedIndexChanged += delegate { UpdatePlotControls(); };
        }

        if (gridName != "-")
        {
            var tiers = ParseTiers(tierNames);
            var intervals = ParseIds(intervalTierIds);
            cropTier = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Dock = DockStyle.Fill, Name = "CropTier" };
            displayTier = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Dock = DockStyle.Fill, Name = "DisplayTier" };
            textGridFont = Choice(new[] { "Times", "Helvetica", "Palatino", "Courier" }, Index(settings[14], 1, 4));
            cropTier.Items.Add(new TierChoice(0, "Do not crop"));
            displayTier.Items.Add(new TierChoice(0, "No TextGrid"));
            foreach (var tier in tiers)
            {
                displayTier.Items.Add(tier);
                if (intervals.Contains(tier.Id))
                    cropTier.Items.Add(tier);
            }
            SelectId(cropTier, Integer(settings[12]));
            SelectId(displayTier, Integer(settings[13]));
            var textGridSection = Section("TextGrid");
            AddPair(textGridSection, "Crop to interval tier", cropTier, "Display tier", displayTier);
            AddPair(textGridSection, "TextGrid font", textGridFont, "", showBoundaries);
            sections.Controls.Add(textGridSection);
        }
        else
        {
            cropTier = null;
            displayTier = null;
            textGridFont = null;
        }

        var buttons = new FlowLayoutPanel {
            Dock = DockStyle.Fill, AutoSize = true, FlowDirection = FlowDirection.RightToLeft, WrapContents = false
        };
        var drawAndExit = new Button { Text = "Draw & Exit", UseMnemonic = false, AutoSize = true, Name = "DrawAndExit" };
        var draw = new Button { Text = "Draw", AutoSize = true, Name = "Draw" };
        var cancel = new Button { Text = "Cancel", AutoSize = true, DialogResult = DialogResult.Cancel, Name = "Cancel" };
        draw.Click += delegate { SaveResult(2); };
        drawAndExit.Click += delegate { SaveResult(3); };
        buttons.Controls.Add(drawAndExit);
        buttons.Controls.Add(draw);
        buttons.Controls.Add(cancel);
        root.Controls.Add(buttons, 0, 2);
        AcceptButton = drawAndExit;
        CancelButton = cancel;
        sections.Height = sections.Controls.Cast<Control>().Sum(control => control.Height + control.Margin.Vertical);
        int desiredHeight = sections.Height + 150;
        int maximumHeight = Screen.FromPoint(Cursor.Position).WorkingArea.Height - 60;
        ClientSize = new Size(660, Math.Max(400, Math.Min(desiredHeight, maximumHeight)));
        UpdatePlotControls();
    }

    private void SaveResult(int action)
    {
        var titleValue = title.Text;
        if (titleValue.IndexOfAny(new[] { '\r', '\n', '\t' }) >= 0)
        {
            MessageBox.Show(this, "The image title cannot contain tabs or line breaks.", Text, MessageBoxButtons.OK, MessageBoxIcon.Information);
            title.Focus();
            return;
        }
        if (windowWidth.Value <= 0 ||
            (!spectrogramOnly && (
                (plotType.SelectedIndex <= 2 && minimumF0.Value <= 0) ||
                (plotType.SelectedIndex <= 1 && maximumF0.Value <= minimumF0.Value))) ||
            (!spectrogramOnly && plotType.SelectedIndex == 2 && maximumDb.Value <= minimumDb.Value))
        {
            MessageBox.Show(this, "Check the plot limits. Maximum values must be greater than minimum values.", Text, MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }
        if (!spectrogramOnly && plotType.SelectedIndex == 3 && !paintSpectrogram.Checked &&
            !drawWaveform.Checked && (displayTier == null || ((TierChoice)displayTier.SelectedItem).Id == 0))
        {
            MessageBox.Show(this, "Choose at least one display element for Background only.", Text, MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }

        var values = new List<string>();
        values.Add(Format(smoothing.Value));
        values.Add(Bit(paintSpectrogram.Checked));
        values.Add(Bit(drawWaveform.Checked));
        values.Add(Format(windowWidth.Value));
        values.Add(Format(minimumF0.Value));
        values.Add(Format(maximumF0.Value));
        values.Add(Format(minimumDb.Value));
        values.Add(Format(maximumDb.Value));
        values.Add((plotType.SelectedIndex + 1).ToString(CultureInfo.InvariantCulture));
        values.Add((f0Scale.SelectedIndex + 1).ToString(CultureInfo.InvariantCulture));
        values.Add((secondaryParameter.SelectedIndex + 1).ToString(CultureInfo.InvariantCulture));
        values.Add((font.SelectedIndex + 1).ToString(CultureInfo.InvariantCulture));
        values.Add(cropTier == null ? "0" : ((TierChoice)cropTier.SelectedItem).Id.ToString(CultureInfo.InvariantCulture));
        values.Add(displayTier == null ? "0" : ((TierChoice)displayTier.SelectedItem).Id.ToString(CultureInfo.InvariantCulture));
        values.Add(textGridFont == null ? "1" : (textGridFont.SelectedIndex + 1).ToString(CultureInfo.InvariantCulture));
        values.Add(Bit(showBoundaries.Checked));

        string titleToken = Guid.NewGuid().ToString("N");
        System.IO.File.WriteAllText(
            System.IO.Path.Combine(resultDirectory, "plot-title-" + titleToken + ".txt"),
            titleValue,
            Encoding.Unicode);
        Result = "OK " + titleToken + " " +
            String.Join(" ", values.ToArray()) + " " + action.ToString(CultureInfo.InvariantCulture) + "\n";
        DialogResult = DialogResult.OK;
        Close();
    }

    private void UpdatePlotControls()
    {
        if (spectrogramOnly)
            return;
        int type = plotType.SelectedIndex + 1;
        bool f0 = type == 1 || type == 2;
        f0Scale.Enabled = f0;
        minimumF0.Enabled = f0;
        maximumF0.Enabled = f0;
        secondaryParameter.Enabled = type == 1;
        smoothing.Enabled = type == 2;
        minimumDb.Enabled = type == 3;
        maximumDb.Enabled = type == 3;
    }

    private static NumericUpDown Number(string value, decimal minimum, decimal maximum, int decimals)
    {
        var control = new NumericUpDown {
            Minimum = minimum, Maximum = maximum, DecimalPlaces = decimals,
            Increment = decimals == 0 ? 1 : 0.1m, Dock = DockStyle.Fill,
            ThousandsSeparator = false, TextAlign = HorizontalAlignment.Left
        };
        decimal parsed;
        if (!Decimal.TryParse(value, NumberStyles.Float, CultureInfo.InvariantCulture, out parsed))
            throw new ArgumentException("A saved plot setting is not a valid number.");
        if (parsed < minimum || parsed > maximum)
            throw new ArgumentException("A saved plot setting is outside the Windows UI's supported range.");
        control.Value = parsed;
        return control;
    }

    private static ComboBox Choice(string[] options, int index)
    {
        var control = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Dock = DockStyle.Fill };
        control.Items.AddRange(options);
        control.SelectedIndex = index - 1;
        return control;
    }

    private static GroupBox Section(string label)
    {
        var section = new GroupBox {
            Text = label, Width = 620, Height = 42, AutoSize = false,
            Padding = new Padding(8, 22, 8, 8), Margin = new Padding(0, 0, 0, 8)
        };
        var layout = new TableLayoutPanel {
            Dock = DockStyle.Fill, ColumnCount = 4, RowCount = 0, GrowStyle = TableLayoutPanelGrowStyle.AddRows
        };
        layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 25));
        layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 25));
        layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 25));
        layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 25));
        section.Controls.Add(layout);
        return section;
    }

    private static void AddRow(GroupBox section, string label, Control control)
    {
        int row = AddSectionRow(section);
        AddSectionLabel(section, label, 0, row);
        AddSectionControl(section, control, label, 1, row, 3);
    }

    private static void AddPair(GroupBox section, string leftLabel, Control left, string rightLabel, Control right)
    {
        int row = AddSectionRow(section);
        AddSectionLabel(section, leftLabel, 0, row);
        AddSectionControl(section, left, leftLabel, 1, row, 1);
        AddSectionLabel(section, rightLabel, 2, row);
        AddSectionControl(section, right, rightLabel, 3, row, 1);
    }

    private static void AddChecksRow(GroupBox section, Control left, Control right)
    {
        int row = AddSectionRow(section);
        AddSectionControl(section, left, left.Text, 0, row, right == null ? 4 : 2);
        if (right != null)
            AddSectionControl(section, right, right.Text, 2, row, 2);
    }

    private static int AddSectionRow(GroupBox section)
    {
        var layout = (TableLayoutPanel)section.Controls[0];
        int row = layout.RowCount++;
        layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 36));
        section.Height = 42 + layout.RowCount * 36;
        return row;
    }

    private static void AddSectionLabel(GroupBox section, string text, int column, int row)
    {
        var layout = (TableLayoutPanel)section.Controls[0];
        var label = new Label {
            Text = text, AutoSize = true, Anchor = AnchorStyles.Left,
            MaximumSize = new Size(140, 0), Margin = new Padding(3)
        };
        layout.Controls.Add(label, column, row);
    }

    private static void AddSectionControl(GroupBox section, Control control, string accessibleName, int column, int row, int columnSpan)
    {
        var layout = (TableLayoutPanel)section.Controls[0];
        if (accessibleName != "")
            control.AccessibleName = accessibleName;
        else if (String.IsNullOrEmpty(control.AccessibleName))
            control.AccessibleName = control.Text;
        control.Margin = new Padding(3);
        layout.Controls.Add(control, column, row);
        layout.SetColumnSpan(control, columnSpan);
    }

    private static List<TierChoice> ParseTiers(string value)
    {
        var tiers = new List<TierChoice>();
        if (value == "-")
            return tiers;
        var lines = value.Split('\n');
        for (int i = 0; i < lines.Length; i++)
        {
            int separator = lines[i].IndexOf('\t');
            if (separator <= 0)
                throw new ArgumentException("A TextGrid tier could not be read.");
            int id = Integer(lines[i].Substring(0, separator));
            string name = lines[i].Substring(separator + 1).TrimEnd('\r');
            tiers.Add(new TierChoice(id, id.ToString(CultureInfo.InvariantCulture) + ": " + name));
        }
        return tiers;
    }

    private static List<int> ParseIds(string value)
    {
        var ids = new List<int>();
        if (value == "-")
            return ids;
        foreach (string part in value.Split(','))
            ids.Add(Integer(part));
        return ids;
    }

    private static void SelectId(ComboBox combo, int id)
    {
        for (int i = 0; i < combo.Items.Count; i++)
        {
            if (((TierChoice)combo.Items[i]).Id == id)
            {
                combo.SelectedIndex = i;
                return;
            }
        }
        combo.SelectedIndex = 0;
    }

    private static int Index(string value, int minimum, int maximum)
    {
        int parsed = Integer(value);
        return Math.Max(minimum, Math.Min(maximum, parsed));
    }

    private static int Integer(string value)
    {
        int parsed;
        if (!Int32.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out parsed))
            throw new ArgumentException("A plot setting was not a valid whole number.");
        return parsed;
    }

    private static bool Flag(string value)
    {
        return value == "1";
    }

    private static string Bit(bool value)
    {
        return value ? "1" : "0";
    }

    private static string Format(decimal value)
    {
        return value.ToString(CultureInfo.InvariantCulture);
    }
}
