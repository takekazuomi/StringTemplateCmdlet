using System.Collections;
using System.Collections.ObjectModel;
using System.Linq;
using System.Management.Automation;
using System.Text;
using Antlr4.StringTemplate;
using Antlr4.StringTemplate.Visualizer.Extensions;
using StringTemplateModule;

// http://www.powershellmagazine.com/2014/03/18/writing-a-powershell-module-in-c-part-1-the-basics/

// PSObject をstringtemplateから触れるようにするために。ObjectModelAdaptor が
// https://github.com/antlr/antlrcs/blob/master/Antlr4.StringTemplate/Misc/ObjectModelAdaptor.cs

namespace StringTemplateCmdlet
{
    [Cmdlet(VerbsData.Convert, "StTemplate")]
    public class ConvertStTemplate : BaseStTemplate
    {
        [Parameter(ValueFromPipeline = true, HelpMessage = "specifies the input objects.")]
        public PSObject InputObject { get; set; }

        [Parameter(HelpMessage = "show visualizer.")]
        public SwitchParameter Visualize { get; set; } = false;

        private Collection<PSObject> _pipelineObjects;

        protected override void BeginProcessing()
        {
            _pipelineObjects = new Collection<PSObject>();
        }

        protected override void ProcessRecord()
        {
            if (InputObject != null)
                _pipelineObjects.Add(InputObject);
        }

        protected override void EndProcessing()
        {
            if (_template == null)
                _template = new Template(TemplateString, DelimiterStartChar, DelimiterStopChar);

            _template.Group.RegisterModelAdaptor(typeof(PSObject), new PSObjectModelAdaptor {WriteVerbose = WriteVerbose});
            _template.Group.RegisterRenderer(typeof(string), new JsonRenderer());
//            _template.Group.RegisterRenderer(typeof(bool), new JsonRenderer());

            if (_runtimeDefinedParameterDictionary != null)
            {
                // The value specified by the dynamic parameter is used.
                // Others set what comes from the pipeline.
                foreach (var key in _runtimeDefinedParameterDictionary.Keys)
                {
                    var param = _runtimeDefinedParameterDictionary[key];
                    if (param.Value == null && _pipelineObjects.Any())
                    {
                        Dump(key, _pipelineObjects);
                        _template.Add(key, _pipelineObjects);
                    }
                    else
                    {
                        if (param.Value != null)
                        {
                            Dump(key, param.Value);
                            _template.Add(key, param.Value);
                        }
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
            _pipelineObjects.Clear();
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
                data?.GetType().Name);
            WriteVerbose(sb.ToString().TrimEnd(',', ' '));
        }
    }
}
