SELECT *
FROM js(
(
  SELECT JSON_EXTRACT_SCALAR(item, '$.sitelinks.enwiki.title') title, item
  FROM [fh-bigquery:wikidata.latest_raw] 
  WHERE LENGTH(item)>10
  HAVING title IS NOT null
),
title, item,
"[{name: 'id', type:'string'},
  {name: 'en_label', type:'string'},
  {name: 'en_wiki', type:'string'},
  {name: 'en_description', type:'string'},
  {name: 'type', type:'string'},
  {name: 'sitelinks', type:'record', mode:'repeated', fields: [{name: 'site', type: 'string'},{name: 'title', type: 'string'},{name: 'encoded', type: 'string'}]},
  {name: 'descriptions', type:'record', mode:'repeated', fields: [{name: 'language', type: 'string'},{name: 'value', type: 'string'}]},
  {name: 'labels', type:'record', mode:'repeated', fields: [{name: 'language', type: 'string'},{name: 'value', type: 'string'}]},
  {name: 'aliases', type:'record', mode:'repeated', fields: [{name: 'language', type: 'string'},{name: 'value', type: 'string'}]},
  {name: 'instance_of', type:'record', mode:'repeated', fields: [{name: 'numeric_id', type: 'integer'}]},
  {name: 'gender', type:'record', mode:'repeated', fields: [{name: 'numeric_id', type: 'integer'}]},
  {name: 'date_of_birth', type:'record', mode:'repeated', fields: [{name: 'time', type: 'string'}]},
  {name: 'date_of_death', type:'record', mode:'repeated', fields: [{name: 'time', type: 'string'}]},
  {name: 'place_of_birth', type:'record', mode:'repeated', fields: [{name: 'numeric_id', type: 'integer'}]},
  {name: 'country_of_citizenship', type:'record', mode:'repeated', fields: [{name: 'numeric_id', type: 'integer'}]},
  {name: 'country', type:'record', mode:'repeated', fields: [{name: 'numeric_id', type: 'integer'}]},
  {name: 'occupation', type:'record', mode:'repeated', fields: [{name: 'numeric_id', type: 'integer'}]},
  {name: 'instrument', type:'record', mode:'repeated', fields: [{name: 'numeric_id', type: 'integer'}]},
  {name: 'genre', type:'record', mode:'repeated', fields: [{name: 'numeric_id', type: 'integer'}]},
  {name: 'coordinate_location', type:'record', mode:'repeated', fields: [{name: 'latitude', type: 'float'}, {name: 'longitude', type: 'float'}, {name: 'altitude', type: 'float'}]},
  {name: 'item', type:'string'}
  ]",
  "function(r, emit) {

  function wikiEncode(x) {
    return x ? encodeURI(x.split(' ').join('_')) : null;
  }

  var obj = JSON.parse(r.item.slice(0, -1));
    
  sitelinks =[];
  for(var i in obj.sitelinks) {
    sitelinks.push({'site':obj.sitelinks[i].site, 'title':obj.sitelinks[i].title, 'encoded':wikiEncode(obj.sitelinks[i].title)}) 
  }  
  descriptions =[];
  for(var i in obj.descriptions) {
    descriptions.push({'language':obj.descriptions[i].language, 'value':obj.descriptions[i].value}) 
  }
  labels =[];
  for(var i in obj.labels) {
    labels.push({'language':obj.labels[i].language, 'value':obj.labels[i].value}) 
  }
  aliases =[];
  for(var i in obj.aliases) {
    for(var j in obj.aliases[i]) {
      aliases.push({'language':obj.aliases[i][j].language, 'value':obj.aliases[i][j].value}) 
    }
  }
  
  function snaks(obj, pnumber, name) {
    var snaks = []
    for(var i in obj.claims[pnumber]) {
      if (!obj.claims[pnumber][i].mainsnak.datavalue) continue;
      var claim = {}
      claim[name]=obj.claims[pnumber][i].mainsnak.datavalue.value[name.split('_').join('-')]
      snaks.push(claim) 
    }
    return snaks
  }
  function snaksLoc(obj, pnumber) {
    var snaks = []
    for(var i in obj.claims[pnumber]) {
      if (!obj.claims[pnumber][i].mainsnak.datavalue) continue;
      var claim = {}
      claim['altitude']=obj.claims[pnumber][i].mainsnak.datavalue.value['altitude']
      claim['longitude']=obj.claims[pnumber][i].mainsnak.datavalue.value['longitude']
      claim['latitude']=obj.claims[pnumber][i].mainsnak.datavalue.value['latitude']
      snaks.push(claim) 
    }
    return snaks
  }
  
  
  instance_of=snaks(obj, 'P31', 'numeric_id');
  gender=snaks(obj, 'P21', 'numeric_id');
  date_of_birth=snaks(obj, 'P569', 'time');
  date_of_death=snaks(obj, 'P569', 'time');
  place_of_birth=snaks(obj, 'P19', 'numeric_id');
  country_of_citizenship=snaks(obj, 'P27', 'numeric_id');
  country=snaks(obj, 'P17', 'numeric_id');
  occupation=snaks(obj, 'P106', 'numeric_id');
  instrument=snaks(obj, 'P1303', 'numeric_id')
  genre=snaks(obj, 'P136', 'numeric_id')
  coordinate_location=snaksLoc(obj, 'P625')
  emit({
    id: obj.id,
    en_wiki: obj.sitelinks.enwiki ? wikiEncode(obj.sitelinks.enwiki.title) : null,
    en_label: obj.labels.en ? obj.labels.en.value : null,
    en_description: obj.descriptions.en ? obj.descriptions.en.value : null,
    type: obj.type,
    labels: labels, 
    descriptions: descriptions,
    sitelinks: sitelinks,
    aliases: aliases,
    instance_of: instance_of,
    gender: gender,
    date_of_birth: date_of_birth,
    date_of_death: date_of_death,
    place_of_birth: place_of_birth,
    country_of_citizenship: country_of_citizenship,
    country: country,
    occupation: occupation,
    instrument: instrument,
    genre: genre,
    coordinate_location: coordinate_location,
    len_item: r.item.length,
    item: r.item
    });  
  }")
