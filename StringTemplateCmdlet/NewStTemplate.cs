using System.Management.Automation;
using Antlr4.StringTemplate;
using StringTemplateModule;

// http://www.powershellmagazine.com/2014/03/18/writing-a-powershell-module-in-c-part-1-the-basics/

namespace StringTemplateCmdlet
{
    [Cmdlet(VerbsCommon.New, "StTemplate")]

    public class NewStTemplate : BaseStTemplate, IDynamicParameters
    {
        protected override void EndProcessing()
        {
            if(Template == null)
                Template = new Template(TemplateString, DelimiterStartChar, DelimiterStopChar);
            WriteObject(Template);
        }
    }
}

