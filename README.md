# MonsterQueries #

## Goals ##

For years I relied on on ActiveRecord and Arel to write my SQL for me and the day I decided to write SQL by hand I gained immense understanding of my database and immense performance. Rails best practices has always taught us to be database agnostic and its a lie. Your database will outlive your web-app, and knowing your database inside and out will make you a better developer. 

**Arel** makes it easy to not write SQL. **MonsterQueries** make it easier to write queries.

## Dependencies ##

### Postgres ###

MonsterQueries is designed for Postgres in mind to take advantage of postgres JSON functions, so you can serve JSON directly to your api endpoints, skipping translating ruby objects into json for maximum performance.

### Handlebars ###

MonsterQueries uses handlebars templating so you can some basic logic in your queries and insert partials

## Directory Structure ##

Monster queries expects all your sql files to be in the directory

```
{RAILS ROOT}/app/queries
```

## Getting SQL ##

You can get sql using the Q module and chaining the path to the file:
```ruby
Q.admin.tasks.index project_id: id
```
->
                     
```sql
app/queries/projects/tasks/index.sql
```

## Passing Params ##
You can pass params to the query which can be then accessed
in the queries using {{}}
```ruby
Q.admin.tasks.index project_id: self.id, count: 5
```                        
```sql
SELECT
  tasks.name,
  {{count}} as count
FROM tasks
WHERE tasks.project_id = {{project_id}}
```
## Partials inside of sql queries ##

You can include other sql partial files inside your sql files.

### /app/queries/tasks/index.sql ###
```sql
{{include 'tasks.select'}}
FROM tasks
WHERE tasks.project_id = {{project_id}}
```
### /app/queries/tasks/select.sql ###
```sql
SELECT
  tasks.name,
  {{count}} as count
```
## Arrays Helper Methods ##

If you need to return a json array as an attribute
```sql
SELECT
  projects.id,
  projects.name,
  {{#array}}
    SELECT
      tasks.id,
      tasks.name
    FROM tasks
    WHERE tasks.project_id = projects.id
  {{/array}} as tasks
FROM projects
WHERE id = {{id}}
```

The array helper will automatically wrap the query with
postgres json functions.

You can also call pass a partial name instead

### /app/queries/projects/show.sql ###
```sql
SELECT
  projects.id,
  projects.name,
  {{array 'tasks.index'}} as tasks
FROM projects
WHERE id = {{id}}
```

### /app/queries/tasks/index.sql ###
```sql
SELECT
  tasks.id,
  tasks.name
FROM tasks
WHERE tasks.project_id = projects.id
```

## Object Helper Methods ##

Same as array but from a single object:

```sql
  SELECT
    tasks.id,
    tasks.name,
    {{#object}}
      SELECT
        projects.id,
        projects.name
      FROM projects
      WHERE projects.id = tasks.project_id
    {{/object}} as project
  FROM tasks
  WHERE tasks.id = {{id}}
```

You can also call pass a partial name instead

### /app/queries/tasks/show.sql ###
```sql
SELECT
  tasks.id,
  tasks.name,
  {{object 'tasks.project'}}
FROM tasks
WHERE tasks.id = {{id}}
```

### /app/queries/tasks/project.sql ###
```sql
SELECT
  projects.id,
  projects.name
FROM projects
WHERE projects.id = tasks.project_id
```


## List of all Helper Methods ##

Helper             | Eg.
-------------------|----------------------------------------
include            | {{include 'path.to.sql'}} , includes sql
array              | {{array   'path.to.sql'}} , json array
object             | {{object  'path.to.sql'}} , json object
paginate           | {{paginate 'path.to.sql'}}
paginate_offset    | {{paginate_offset}}
wildcard           | {{wildcard name}}, same as '%column%'
quote              | {{quote name}} , wrap in quotes
int                | {{int name}}
float              | {float name}}

This project rocks and uses MIT-LICENSE.

