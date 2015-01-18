# Variation code holder which maps a filePath to the variation code.
module.exports =
class VariationHolder
  map = {}

  # Associate the specified variation code {String} with the specified
  # filePath.
  #
  # filePath: The {String} file path with which the specified variation is to
  #  be associated.
  # variation: The {String} variation code to be associated with the specified
  #  filePath.
  @putVariation: (filePath, variation) ->
    map[filePath] = variation

  # Return the variation code {String} to which the specified filePath
  # is assosiated.
  #
  # filePath: The {String} file path whose associated value is to be returned.
  #
  # Returns a {String} variation code.
  @getVariation: (filePath) ->
    map[filePath]
