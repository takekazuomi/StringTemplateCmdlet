using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Antlr4.StringTemplate;
using Antlr4.StringTemplate.Misc;

namespace StringTemplateModule
{
    public class MapModelAdaptorWrapper:MapModelAdaptor
    {
        public Action<string> WriteVerbose { set; get; }

        public override object GetProperty(Interpreter interpreter, TemplateFrame frame, object o, object property, string propertyName)
        {
            object value;
            IDictionary map = (IDictionary)o;

            if (property == null)
                value = map[TemplateGroup.DefaultKey];
            else if (property.Equals("keys"))
                value = map.Keys;
            else if (property.Equals("values"))
                value = map.Values;
            else if (map.Contains(property))
                value = map[property];
            else if (map.Contains(propertyName))
                value = map[propertyName]; // if can't find the key, try ToString version
            else
                value = map[TemplateGroup.DefaultKey]; // not found, use default

            if (object.ReferenceEquals(value, TemplateGroup.DictionaryKey))
            {
                value = property;
            }

            WriteVerbose?.Invoke(string.Format("Type:{0}, property: {1}, propertyName:{2}, value:{3}", o.GetType().Name, property, propertyName, value));

            return value;
        }
    }
}
