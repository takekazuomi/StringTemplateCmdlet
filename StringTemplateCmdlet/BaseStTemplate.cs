using System;
using System.Collections;
using System.Collections.ObjectModel;
using System.Linq;
using System.Management.Automation;
using System.Text;
using Antlr4.StringTemplate;

// http://www.powershellmagazine.com/2014/03/18/writing-a-powershell-module-in-c-part-1-the-basics/

// PSObject をstringtemplateから触れるようにするために。ObjectModelAdaptor が
// https://github.com/antlr/antlrcs/blob/master/Antlr4.StringTemplate/Misc/ObjectModelAdaptor.cs

namespace StringTemplateCmdlet
{
    [Cmdlet(VerbsData.Convert, "StTemplate")]
    public abstract  class BaseStTemplate : PSCmdlet, IDynamicParameters
    {
        [Parameter(ParameterSetName = "anonymous", HelpMessage = "template string", Mandatory = true, Position = 0)]
        public string TemplateString { get; set; }

        [Parameter(ParameterSetName = "group", HelpMessage = "template group directory or group file", Mandatory = true, Position = 0)]
        public string GroupPath { get; set; }

        [Parameter(HelpMessage = "template name", Mandatory = true, Position = 0)]
        public string TemplateName { get; set; }

        [Parameter(HelpMessage = "delimiter start char, default: <")]
        public char DelimiterStartChar { get; set; } = '<';

        [Parameter(HelpMessage = "delimiter end char, default: >")]
        public char DelimiterStopChar { get; set; } = '>';


        protected Template Template;
        protected RuntimeDefinedParameterDictionary RuntimeDefinedParameterDictionary;

        protected bool IsVerbose;

        public virtual  object GetDynamicParameters()
        {
            IsVerbose = MyInvocation.BoundParameters.ContainsKey("Verbose") &&
                        ((SwitchParameter) MyInvocation.BoundParameters["Verbose"]).ToBool();

            try
            {
                if (GroupPath != null && TemplateName != null)
                {
                    var path = System.IO.Path.GetFullPath(GroupPath);
                    TemplateGroup templateGroup;
                    if (path.EndsWith(TemplateGroup.GroupFileExtension, StringComparison.InvariantCultureIgnoreCase))
                    templateGroup = new TemplateGroupFile(path, Encoding.UTF8, DelimiterStartChar, DelimiterStopChar)
                    {
                        Verbose = IsVerbose,
                        Logger = Host.UI.WriteVerboseLine
                    };
                    else
                        templateGroup = new TemplateGroupDirectory(path, Encoding.UTF8, DelimiterStartChar, DelimiterStopChar)
                        {
                            Verbose = IsVerbose,
                            Logger = Host.UI.WriteVerboseLine
                        };

                    Template = templateGroup.GetInstanceOf(TemplateName);
                    var paramDictionary = new RuntimeDefinedParameterDictionary();
                    var attr = Template?.GetAttributes();
                    if (attr != null)
                    {
                        var m = string.Format("top level attributes: {0}", string.Join(", ", attr.Keys));

                        Host.UI.WriteVerboseLine(m);
                        foreach (var key in attr.Keys)
                        {
                            var attribute = new ParameterAttribute
                            {
                                ValueFromPipeline = true,
                                ValueFromPipelineByPropertyName = true
                            };
                            var attributeCollection = new Collection<System.Attribute> {attribute};
                            var param = new RuntimeDefinedParameter(key, typeof(object), attributeCollection);
                            paramDictionary.Add(key, param);
                        }
                        RuntimeDefinedParameterDictionary = paramDictionary;
                    }
                    else
                    {
                        Host.UI.WriteWarningLine("no top level attribute");
                    }
                    return paramDictionary;
                }
            }
            catch (Exception e)
            {
                var m = string.Format("In GetDynamicParameters: {0}", e);
                Host.UI.WriteVerboseLine(m);
                throw;
            }
            return null;
        }

        private void Dump(string  key, object data)
        {
            if(!IsVerbose) 
                return;

            var e = data as IEnumerable;
            var sb= new StringBuilder();
            sb.AppendFormat("Attribute:{0}, Type: ", key);
            sb.AppendLine(
                e != null ?
                string.Join(", ", e.Cast<object>().Select(o => o.GetType().Name)) : 
                data.GetType().Name);
            WriteVerbose(sb.ToString().TrimEnd(',', ' '));
        }
    }
}
