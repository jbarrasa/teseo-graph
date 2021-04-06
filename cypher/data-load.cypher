//index creation
create index on :PhDThesis(id)
create index on :University(id)


//load universities
load csv with headers from "file:///Universidades.txt" as row FIELDTERMINATOR ';' with row
where row.Universidad is not null
merge (u:University { id: row.ID_uni }) on create set u.name = row.Universidad


//load thesis
:auto profile USING PERIODIC COMMIT 500
load csv with headers from "file:///Tesis.txt" as row FIELDTERMINATOR ';' with row 
where row.ID_uni is not null and replace(row.Fecha_lectura," ","") =~ "\\d{4}\\-\\d{2}\\-\\d{2}"
merge (u:University { id: row.ID_uni })
create (t:PhDThesis { id: row.ID, url: row.URL })-[:IN_UNI]->(u) set t.title = row.Titulo, t.year = toInteger(substring(row.Year,0,4)), t.dissertationDate = date(replace(row.Fecha_lectura," ","")), t.dept = row.Departamento


//load authors
:auto profile USING PERIODIC COMMIT 500
load csv with headers from "file:///Instancias_autoria.txt" as row FIELDTERMINATOR ';' 
match (pdt:PhDThesis {id: row.ID_tesis})
create (p:Person {id: row.ID_instancia_Autor, name : row.Etiqueta_nombre})-[:AUTHOR]->(pdt)


//load directors
:auto profile USING PERIODIC COMMIT 5000
load csv with headers from "file:///Instancias_direccion.txt" as row FIELDTERMINATOR ';' with row
where row.Etiqueta_nombre is not null
match (pdt:PhDThesis {id: row.ID_tesis})
create (p:Person {id: row.ID_instancia_direccion, name : row.Etiqueta_nombre})-[:SUPERVISE { role: row.Rol }]->(pdt)

//load dissertation jury
:auto profile USING PERIODIC COMMIT 5000
load csv with headers from "file:///instancias_pertenencia_tribunales.txt" as row FIELDTERMINATOR ';' with row
where row.Etiqueta_nombre is not null
match (pdt:PhDThesis {id: row.ID_tesis})
create (p:Person {id: row.Id_participacion_trib, name : row.Etiqueta_nombre})-[:IN_JURY { role: row.Rol }]->(pdt)

//config for importing RDF data
CALL n10s.graphconfig.init( 
           { handleVocabUris: "IGNORE", handleMultival : "ARRAY", keepLangTag : true } );

CREATE CONSTRAINT n10s_unique_uri ON (r:Resource) ASSERT r.uri IS UNIQUE

//import unesco nomenclature
CALL n10s.rdf.import.fetch(
"https://skos.um.es/sparql/?query=" + apoc.text.urlencode($sparql) + "&output=turtle", "Turtle", 
{ predicateExclusionList : ["http://www.w3.org/2004/02/skos/core#topConceptOf", "http://www.w3.org/2004/02/skos/core#inScheme"]})

