{{#unless count}}
  {{#if order}}
    ORDER BY {{order}}
    {{#if order_dir}}
      {{order_dir}}
    {{else}}
      ASC
    {{/if}}
  {{/if}}
  LIMIT {{per_page}}
  {{#if page}}
    OFFSET (({{page}} - 1) * {{per_page}})
  {{/if}}
{{/unless}}

