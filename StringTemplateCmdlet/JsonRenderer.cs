/*
 * [The "BSD licence"]
 * Copyright (c) 2011 Terence Parr
 * All rights reserved.
 *
 * Conversion to C#:
 * Copyright (c) 2011 Sam Harwell, Tunnel Vision Laboratories, LLC
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

using System.Runtime.Serialization;
using System.Security;
using System.Text;
using System.Web;
using Antlr4.StringTemplate;
using CultureInfo = System.Globalization.CultureInfo;

namespace StringTemplateCmdlet
{
    public class JsonRenderer : IAttributeRenderer
    {
        // trim(s) and strlen(s) built-in funcs; these are Format options
        public virtual string ToString(object o, string formatString, CultureInfo culture)
        {
            string s = (string)o;
            if (formatString == null)
                return s;

            if (formatString.Equals("upper"))
                return culture.TextInfo.ToUpper(s);

            if (formatString.Equals("lower"))
                return culture.TextInfo.ToLower(s);

            if (formatString.Equals("cap"))
                return s.Length > 0 ? culture.TextInfo.ToUpper(s[0]) + s.Substring(1) : s;

            if (formatString.Equals("json-encode"))
                return JsonToString(o);

            if (formatString.Equals("url-encode"))
                return HttpUtility.UrlEncode(s, Encoding.UTF8);

            if (formatString.Equals("xml-encode"))
            {
                return SecurityElement.Escape(s);
            }

            return string.Format(culture, formatString, s);
        }

        protected string JsonToString(object o)
        {
            string v;

            if (o is bool)
                v = (bool)o ? "true" : "false";
            else if (o is int || o is long)
                v = o.ToString();
            else
                v = HttpUtility.JavaScriptStringEncode(o.ToString(), true).Replace("\\u0027", "'").Replace("\\u0026", "&");
            return v;
        }
    }
}
