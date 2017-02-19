{{#unless count}}
  LIMIT {{per_page}}
  {{#if page}}
    OFFSET (({{page}} - 1) * {{per_page}})
  {{/if}}
{{/unless}}

