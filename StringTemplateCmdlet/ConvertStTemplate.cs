using System;
using System.Collections;
using System.Collections.ObjectModel;
using System.Linq;
using System.Management.Automation;
using System.Text;
using Antlr4.StringTemplate;
using Antlr4.StringTemplate.Visualizer.Extensions;

// http://www.powershellmagazine.com/2014/03/18/writing-a-powershell-module-in-c-part-1-the-basics/

// PSObject をstringtemplateから触れるようにするために。ObjectModelAdaptor が
// https://github.com/antlr/antlrcs/blob/master/Antlr4.StringTemplate/Misc/ObjectModelAdaptor.cs

namespace StringTemplateModule
{
    [Cmdlet(VerbsData.Convert, "StTemplate")]
    public class ConvertStTemplate : PSCmdlet, IDynamicParameters
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

        [Parameter(ValueFromPipeline = true, HelpMessage = "specifies the input objects.")]
        public PSObject InputObject { get; set; }
        
        private Template _template;
        private RuntimeDefinedParameterDictionary _runtimeDefinedParameterDictionary;

        [Parameter(HelpMessage = "show visualizer.")]
        public SwitchParameter Visualize { get; set; } = false;

        private bool isVerbose;

        public object GetDynamicParameters()
        {
            isVerbose = MyInvocation.BoundParameters.ContainsKey("Verbose");

            try
            {
                if (GroupPath != null)
                {
                    var path = System.IO.Path.GetFullPath(GroupPath);
                    TemplateGroup templateGroup;
                    if (path.EndsWith(TemplateGroup.GroupFileExtension, StringComparison.InvariantCultureIgnoreCase))
                        templateGroup = new TemplateGroupFile(path, Encoding.UTF8, DelimiterStartChar, DelimiterStopChar) {Verbose = isVerbose};
                    else
                        templateGroup = new TemplateGroupDirectory(path, Encoding.UTF8, DelimiterStartChar, DelimiterStopChar) {Verbose = isVerbose};

                    _template = templateGroup.GetInstanceOf(TemplateName);
                    var paramDictionary = new RuntimeDefinedParameterDictionary();
                    var attr = _template.GetAttributes();
                    //var attr = _template.
                    if (attr != null)
                    {
                        var m = string.Format("top level attributes: {0}", string.Join(", ", attr.Keys));

                        //WriteDebug(m);
                        foreach (var key in attr.Keys)
                        {
                            var attribute = new ParameterAttribute();
//                            attribute.ValueFromPipeline = true;
//                            attribute.ValueFromPipelineByPropertyName = true;
                            var attributeCollection = new Collection<System.Attribute> {attribute};
                            var param = new RuntimeDefinedParameter(key, typeof(object), attributeCollection);
                            paramDictionary.Add(key, param);
                        }
                        _runtimeDefinedParameterDictionary = paramDictionary;
                    }
                    else
                    {
                        Host.UI.WriteWarningLine("no top level attribute");
                        //WriteDebug("no top level attribute");
                    }
                    return paramDictionary;
                }
            }
            catch (Exception e)
            {
                var m = string.Format("in GetDynamicParameters: {0}", e);
                //WriteDebug(m);
                throw;
            }
            return null;
        }

        private Collection<PSObject> pipelineObjects;

        protected override void BeginProcessing()
        {
            pipelineObjects = new Collection<PSObject>();
        }

        protected override void ProcessRecord()
        {
            if (InputObject != null)
                pipelineObjects.Add(InputObject);
        }

        protected override void EndProcessing()
        {
            if (_template == null)
                _template = new Template(TemplateString, DelimiterStartChar, DelimiterStopChar);

            _template.Group.RegisterModelAdaptor(typeof(PSObject), new PSObjectModelAdaptor {WriteVerbose = WriteVerbose});
            //_template.Group.RegisterModelAdaptor(typeof(IDictionary), new MapModelAdaptorWrapper());

            if (_runtimeDefinedParameterDictionary != null)
            {
                // The value specified by the dynamic parameter is used.
                // Others set what comes from the pipeline.
                foreach (var key in _runtimeDefinedParameterDictionary.Keys)
                {
                    var param = _runtimeDefinedParameterDictionary[key];
                    if (param.Value == null && pipelineObjects.Any())
                    {
                        Dump(key, pipelineObjects);
                        _template.Add(key, pipelineObjects);
                    }
                    else
                    {
                        Dump(key, param.Value);
                        _template.Add(key, param.Value);
                    }
                }
            }
            if (Visualize)
            {
                _template.Visualize();
            }
            else
            {
                WriteObject(_template.Render());
            }
            pipelineObjects.Clear();
        }

        private void Dump(string  key, object data)
        {
            if(!isVerbose) 
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
