import module namespace  cmpx = 'quodatum.cmpx';
declare namespace comp="urn:quodatum:qd-cmpx:component";

let $a:=(
  map{  "name":"ace","version":"1.4.8"},
   map{  "name": "vuetify","version": "2.1.9"},
    map{  "name": "vue","version": "2.6.11"},
    map{  "name": "vuex","version": "3.0.1"},
    map{  "name": "vue-router","version": "3.1.6"},
   map{  "name":  "vue-treeselect","version": "0.0.25"},
   map{  "name":  "google-material","version":"0.0.0"},
   map{  "name":  "js-beautify","version": "1.9.0"},
    map{  "name": "axios","version": "0.18.1"},
   map{  "name":  "qs","version": "6.4.0"},
    map{  "name":   "localforage","version": "1.7.1"},
    map{  "name":  "momentjs","version": "2.24.0"},
    map{  "name":  "vuetify-jsonschema-form","version": "0.27.1"},
    map{  "name":  "prism","version": "1.15.0"},
    map{  "name": "vue-prism-component","version": "1.1.1"},
    map{  "name":  "vis-timeline-graph2d","version": "4.21.0"}
)
return  $a!cmpx:status-enrich(.,cmpx:comps())=>filter(function($a){empty($a?found)})