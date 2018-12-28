# qd-cmpx

A component database. 
Stores locations, versions and dependencies for Expath and browser based components.
Can generate http include files to load a set of components.

## Install
```xquery
import module namespace  cmpx = 'quodatum.cmpx';
(: load database :)
cmpx:load()
```
## Examples
cmpx:expath-pkg("abide")
 return the expath doc for web application $name
 
 cmpx:app($name)
 return dependancy map for web app $name
 
components raw data
````
cmpx:comps()
````
list all names
````
cmpx:comps()!cmpx:names(.)
angular-tree-control
jquery
twitter-bootstrap
twitter-bootstrap-css
moment
angular-moment
scrollTo
lodash
````
find from name
````
cmpx:get("angular-tree-control")
<cmp xmlns="urn:quodatum:qd-cmpx:component" name="angular-tree-control">
  <runat>browser</runat>
  <tagline>The AngularJS tree component.</tagline>
  <depends>angularjs</depends>
  <home>http://wix.github.io/angular-tree-control/</home>
  <licence>MIT</licence>
  <release version="0.2.0">
    <location offline="true" base="/static/lib/angular-tree-control/0.2.0/">
      <local type="css">css/tree-control.css</local>
      <local type="js">tree-control.js</local>
    </location>
  </release>
</cmp>
````