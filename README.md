# qd-cmpx

A component database. 
Stores locations, versions and dependancies for Expath and browser based components.
Can generate http include files to load a set of components.


## Examples
cmpx:expath-pkg($name)
 return the expath doc for web application $name
 
 cmpx:app($name)
 return dependancy map for web app $name
 
components raw data
````
$cmpx:comps
````
list all names
````
cmpx:names($cmpx:comps)
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
cmp:find("angular-tree-control")
<cmp xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="angular-tree-control">
  <runat>browser</runat>
  <tagline>The AngularJS tree component.</tagline>
  <depends>angularjs</depends>
  <home>http://wix.github.io/angular-tree-control/</home>
  <licence>MIT</licence>
  <release version="0.2.0">
    <local type="css">lib/angular-tree-control/0.2.0/css/tree-control.css</local>
    <local type="js">lib/angular-tree-control/0.2.0/tree-control.js</local>
  </release>
</cmp>
````