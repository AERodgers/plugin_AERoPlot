using System;
using System.Collections.Generic;
using System.Drawing;
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
            if (args.Length != 3)
                throw new ArgumentException("Expected a Sound name, a TextGrid name, and a list of tiers.");
            string[] tiers = args[2].Split('\n');
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            using (var window = new TableWindow(args[0], args[1], tiers))
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
            MessageBox.Show(error.Message, "AERoPlot prototype", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }
}

internal sealed class TableWindow : Form
{
    private readonly TextBox tableName = new TextBox();
    private readonly ComboBox baseTier = new ComboBox();
    private readonly CheckedListBox otherTiers = new CheckedListBox();
    private readonly CheckBox baseTimesOnly = new CheckBox();
    public string Result { get; private set; }

    public TableWindow(string sound, string grid, string[] tiers)
    {
        Text = "AERoPlot - Create Table (prototype)";
        StartPosition = FormStartPosition.CenterScreen;
        MinimumSize = new Size(520, 510);
        Size = new Size(600, 570);
        Font = SystemFonts.MessageBoxFont;

        var layout = new TableLayoutPanel {
            Dock = DockStyle.Fill, Padding = new Padding(14), ColumnCount = 1, RowCount = 10
        };
        layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
        layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        Controls.Add(layout);

        layout.Controls.Add(LabelFor("Sound: " + sound + "    TextGrid: " + grid), 0, 0);
        layout.Controls.Add(LabelFor("Table name"), 0, 1);
        tableName.Text = "aeroplot_table";
        tableName.Dock = DockStyle.Fill;
        layout.Controls.Add(tableName, 0, 2);
        layout.Controls.Add(LabelFor("Base tier (one row per labelled interval or point)"), 0, 3);
        baseTier.DropDownStyle = ComboBoxStyle.DropDownList;
        baseTier.Dock = DockStyle.Fill;
        baseTier.Items.AddRange(tiers);
        baseTier.SelectedIndex = 0;
        layout.Controls.Add(baseTier, 0, 4);
        layout.Controls.Add(LabelFor("Other tiers to include"), 0, 5);
        layout.Controls.Add(LabelFor("Select the tiers that contain information you want to include."), 0, 6);
        otherTiers.Dock = DockStyle.Fill;
        otherTiers.CheckOnClick = true;
        otherTiers.Items.AddRange(tiers);
        layout.Controls.Add(otherTiers, 0, 7);
        baseTimesOnly.Text = "Include times for the base tier only";
        baseTimesOnly.AutoSize = true;
        baseTimesOnly.Checked = true;
        layout.Controls.Add(baseTimesOnly, 0, 8);

        var buttons = new FlowLayoutPanel { Dock = DockStyle.Fill, AutoSize = true, FlowDirection = FlowDirection.RightToLeft };
        var create = new Button { Text = "Create Table", AutoSize = true };
        var cancel = new Button { Text = "Cancel", AutoSize = true, DialogResult = DialogResult.Cancel };
        create.Click += CreateClicked;
        buttons.Controls.Add(create);
        buttons.Controls.Add(cancel);
        layout.Controls.Add(buttons, 0, 9);
        AcceptButton = create;
        CancelButton = cancel;
    }

    private static Label LabelFor(string text)
    {
        return new Label { Text = text, AutoSize = true, Padding = new Padding(0, 5, 0, 3), MaximumSize = new Size(540, 0) };
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
        var indexes = new List<string>();
        foreach (int index in otherTiers.CheckedIndices)
            indexes.Add((index + 1).ToString(System.Globalization.CultureInfo.InvariantCulture));
        Result = "OK\n" + name + "\n" + (baseTier.SelectedIndex + 1) + "\n" +
            (baseTimesOnly.Checked ? "1" : "0") + "\n" +
            (indexes.Count == 0 ? "-" : String.Join(",", indexes.ToArray())) + "\n";
        DialogResult = DialogResult.OK;
        Close();
    }
}
