using System;
using System.IO;
using System.Text;
using System.Windows.Forms;

internal static class AsyncUiProbe
{
    [STAThread]
    private static int Main(string[] args)
    {
        try
        {
            if (args.Length != 1)
                throw new ArgumentException("Expected one result file path.");
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            using (var window = new TableWindow("probe sound", "probe grid", new[] { "word" }))
            {
                string result = window.ShowDialog() == DialogResult.OK ? window.Result : "CANCEL\n";
                File.WriteAllText(args[0], result, new UTF8Encoding(false));
            }
            return 0;
        }
        catch (Exception error)
        {
            MessageBox.Show(error.Message, "AERoPlot async probe", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }
}
