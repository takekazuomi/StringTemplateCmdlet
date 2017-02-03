using System.Management.Automation;
using System.Text;
using Antlr4.StringTemplate;

// http://www.powershellmagazine.com/2014/03/18/writing-a-powershell-module-in-c-part-1-the-basics/

namespace StringTemplateModule
{
    [Cmdlet(VerbsCommon.New, "StGroup")]

    public class NewStGroup : PSCmdlet
    {
        [Parameter(HelpMessage = "template string", Mandatory = true, Position = 0)]
        public string Path { get; set; }

        [Parameter(HelpMessage = "template group directory")]
        public char DelimiterStartChar { get; set; } = '<';

        [Parameter(HelpMessage = "template string")]
        public char DelimiterStopChar { get; set; } = '>';


        // https://msdn.microsoft.com/en-us/library/dd878334(v=vs.85).aspx

        protected override void ProcessRecord()
        {
        }

        protected override void EndProcessing()
        {
            var template = new TemplateGroupDirectory(System.IO.Path.GetFullPath(Path), Encoding.UTF8, DelimiterStartChar, DelimiterStopChar)
            {
                Verbose = false,
                Logger = Host.UI.WriteVerboseLine
            };
            WriteObject(template);
        }
    }
}

