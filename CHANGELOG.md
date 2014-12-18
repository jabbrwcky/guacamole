## Version 0.4.0

**Codename: Theatre of Pain**

This release focus on the graph integration of ArangoDB 2.2. We implemented relations on top of graphs. The old implementation for relations **has been removed**. If you still need it **don't just upgrade**.

Notable changes are:

  * Implement relations with a graph (#83)
  * Added section about design to GOALS.md
  * AQL Support is default now (#91)
  * Typo fixes in the README (@badboy, @ifraixedes, @solnic @timoschilling)
  * Internal changes
    * Relations based on foreign keys have been removed


## Version 0.3.0

**Codename: Spread your Wings**

This release improved the configurability of Guacamole, updated Ashikawa::Core, enhanced the README and added callbacks.

Notable changes are:

  * Implemented external callbacks
  * Added support for `DATABASE_URL`
  * Parse `guacamole.yml` with ERB
  * Updated Ashikawa::Core to 0.12.0
  * Improved README
  * Fixed generators with `test_unit`
  * Internal changes
    * Removed `debugger` in favor of `pry`
    * Removed `devtools`


## Version 0.2.0

**Codename: Into the Storm**

This is a quick follow up release to fix some bugs and to introduce some experimental AQL support to get people better started with Guacamole and ArangoDB.

Notable changes are:

 * Improvements to the README (thanks to @janpieper, @tisba, @ujjwalt)
 * Fix the loading of ActiveSupport (#57, #59)
 * Updated to Ashikawa::Core 0.11.0 (#60)
 * Automatically add `app/collections` to the autoload path (#52)
 * Build against Ruby 2.1.2 (#56)
 * Add an experimental support for AQL (#51)

**Note**: As of today release name will be taken from Blind Guardian song titles \m/


## Version 0.1.0

**Codename: The Dawn**

This is the very first release of Guacamole. Please be aware that is alpha software and we don't recommend it to be used in production systems. It is meant to be used in prototypes to help people getting started with ArangoDB in the context of a Rails application. We love to hear about your feedback and impressions on this project.

The main features we added in this release:

 * Added an Identity Map
 * Added lazy associations
 * Fixed hamster dependency
 * Added database related rake tasks
 * Added basic Rails generators
 * Significant improvements to the README, including a getting started guide
 * Using the latest Ashikawa::Core version
 * Some internal improvement to optimize the development process


## Version 0.0.1

Merely a release but a proof of concept.
