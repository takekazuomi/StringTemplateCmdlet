using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace StringTemplateCmdlet
{
    class DefaultJsonRenderer : JsonRenderer
    {
        public override string ToString(object o, string formatString, CultureInfo culture)
        {
            if (formatString == null)
                return JsonToString(o);
            return base.ToString(o, formatString, culture);
        }
    }
}
