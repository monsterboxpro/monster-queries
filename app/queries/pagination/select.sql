SELECT
  {{#if column}}
    COUNT({{column}}) as total_entries,
  {{else}}
    COUNT(*) as total_entries,
  {{/if}}
  {{per_page}} as per_page,
  {{#if page}}
    {{page}} as page
  {{else}}
    1 as page
  {{/if}}
