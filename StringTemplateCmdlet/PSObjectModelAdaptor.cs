using System;
using System.Management.Automation;
using Antlr4.StringTemplate;
using Antlr4.StringTemplate.Misc;

namespace StringTemplateModule
{
    // http://stackoverflow.com/questions/23076965/antlr4-stringtemplate-not-compatible-with-json-net-dynamic-items
    // http://www.programcreek.com/java-api-examples/index.php?api=org.stringtemplate.v4.misc.ObjectModelAdaptor

    public class PSObjectModelAdaptor : ObjectModelAdaptor
    {
        public Action<string> WriteVerbose { set; get; }

        public override object GetProperty(Interpreter interpreter, TemplateFrame frame, object obj, object property, string propertyName)
        {
            WriteVerbose?.Invoke(string.Format("Type:{0}, property: {1}, propertyName:{2}", obj.GetType().Name, property, propertyName));

            var pso = obj as PSObject;
            if (pso != null)
            {
                var value = pso.Properties[propertyName]?.Value;
                if (value == null)
                {
                    return base.GetProperty(interpreter, frame, pso.BaseObject, property, propertyName);
                }
                return value;
            }
            return null;
        }
    }
}
