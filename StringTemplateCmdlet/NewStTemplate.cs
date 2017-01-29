using System;
using System.Collections.ObjectModel;
using System.Linq;
using System.Management.Automation;
using System.Text;
using Antlr4.StringTemplate;

// http://www.powershellmagazine.com/2014/03/18/writing-a-powershell-module-in-c-part-1-the-basics/

namespace StringTemplateModule
{
    [Cmdlet(VerbsCommon.New, "StTemplate")]

    public class NewStTemplate : PSCmdlet, IDynamicParameters
    {
        [Parameter(ParameterSetName = "anonymous", HelpMessage = "template string", Mandatory = true, Position = 0)]
        public string TemplateString { get; set; }

        [Parameter(ParameterSetName = "group", HelpMessage = "template group directory", Mandatory = true, Position = 0)]
        public string GroupPath { get; set; }

        [Parameter(ParameterSetName = "group", HelpMessage = "template name", Mandatory = true, Position = 0)]
        public string TemplateName { get; set; }

        [Parameter(HelpMessage = "delimiter start char, default: <")]
        public char DelimiterStartChar { get; set; } = '<';

        [Parameter(HelpMessage = "delimiter end char, default: >")]
        public char DelimiterStopChar { get; set; } = '>';

        private Template _template;
        
        public object GetDynamicParameters()
        {
            try
            {
                if (GroupPath != null)
                {
                    var templateGroup = new TemplateGroupDirectory(System.IO.Path.GetFullPath(GroupPath), Encoding.UTF8, DelimiterStartChar, DelimiterStopChar) {Verbose = false};
                    _template = templateGroup.GetInstanceOf(TemplateName);
                    var paramDictionary = new RuntimeDefinedParameterDictionary();
                    var attr = _template.GetAttributes();
                    if (attr != null)
                    {
                        var m = string.Format("top level attributes: {0}", string.Join(", ", attr.Keys));
                        WriteVerbose(m);
                        foreach (var key in attr.Keys)
                        {
                            var attribute = new ParameterAttribute();
                            var attributeCollection = new Collection<System.Attribute> {attribute};
                            var param = new RuntimeDefinedParameter(key, typeof(object), attributeCollection);
                            paramDictionary.Add(key, param);
                        }
                        return paramDictionary;
                    }
                    else
                    {
                        WriteVerbose("no top level attribute");
                    }
                }
            }
            catch (Exception e)
            {
                WriteDebug(e.ToString());
            }
            return null;
        }

        protected override void ProcessRecord()
        {
        }

        protected override void EndProcessing()
        {
            if(_template == null)
                _template = new Template(TemplateString, DelimiterStartChar, DelimiterStopChar);
            WriteObject(_template);
        }
    }
}

