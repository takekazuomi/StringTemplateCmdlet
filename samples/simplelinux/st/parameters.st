parameters_x(config) ::= <<
"parameters": {
<config: { p|
  <p.name;format="json-encode"> : {
    "defaultValue": <p.defaultValue;format="json-encode">,
    "type": <p.type;format="json-encode">,
    "metadata":
      <curlybrace("description", p.metadata.description)>
  }
};separator=",">
}
>>
