using System;
using System.Collections;
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
                foreach (var psmi in pso.Members)
                {

                }
                foreach (var pspi in pso.Properties)
                {
                    WriteVerbose?.Invoke(string.Format("dump properties MemberType:{0}, TypeNameOfValue: {1}, Name:{2}, IsGettable:{3}", pspi.MemberType, pspi.TypeNameOfValue, pspi.Name, pspi.IsGettable));
                }
                var pi = pso.Properties[propertyName];

                WriteVerbose?.Invoke(pi != null ? string.Format("propertyName: {0}, name: {1}, MemberType: {2}, IsGettable:{3}, TypeNameOfValue: {4}", propertyName, pi?.Name, pi?.MemberType, pi?.IsGettable, pi?.TypeNameOfValue) : string.Format("propertyName: {0}", propertyName));

                var value = pso.Properties[propertyName]?.Value;
                if (value == null)
                {
                    var adap = frame.Template.Group.GetModelAdaptor(pso.BaseObject.GetType());
                    return adap.GetProperty(interpreter, frame, pso.BaseObject, property, propertyName);
                }
                return value;
            }
            return null;
        }
    }
}
