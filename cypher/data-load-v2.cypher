create index on :University(id);
create index on :PhdThesis(id);

//load from single denormalized file
:auto 
USING PERIODIC COMMIT 1000
load csv with headers from "file:///jobteseo2021-catalogoteseoMuestra-77-86.csv" as row with row limit 100
where row.universidad is not null and row.refdownlink is not null
merge (u:University { id: row.universidad }) on create set u.name = row.Universidad
//merge (d:UniversityDept { id: row.universidad + "/" + row.departamento }) on create set d.name = row.departamento
//merge (u)<-[:BELONGS_TO]-(d)
create (t:PhDThesis { id: row.refdownlink })-[:IN_UNI]->(u) set t.title = row.titulo, t.year = toInteger(substring(row.fecha,0,4)), t.dissertationDate = date(replace(row.fecha," ","")), t.dept = row.departamento, t.summary = row.resumen
WITH t, row
UNWIND [x in split(row.materia,"|") where trim(x) <> ""| x ] as topic 
MERGE (top:Topic { name : trim(topic) })
MERGE (top)<-[:HAS_TOPIC]-(t)
with distinct t, row
create (p:Person {name : row.autor})-[:AUTHOR]->(t)
with distinct t, row
create (p:Person {name : row.director})-[:ADVISOR]->(t)
with distinct t, row
UNWIND [x in split(row.tribunal,"|") where trim(x) <> ""| x ] as member
create (p:Person {name : member})-[:JURY_MEMBER]->(t)
